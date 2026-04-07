# SupplyChain_DataPlatform

## Project Overview
This project is a fully automated data pipeline with Apache Airflow. It pulls data from three different sources, lands everything in Amazon S3 as Parquet files, loads each source into Snowflake using `COPY INTO`, and only proceeds to downstream transformation after every single source has successfully landed and loaded. It uses Terraform to infrastructure-as-code the entire stack, from raw data ingestion, to storage in a data lake, to transformation and querying in a Data Warehouse. All credentials are managed securely through AWS SSM Parameter Store and nothing is hardcoded.

Our Focus here is the data, the tools are the reliable propellers to achieving our desired results.

If anything fails at any point, a Slack alert fires immediately identifying exactly which source broke, which task failed, which run it was, and what the error was. Nothing moves forward until everything is clean.
The pipeline is designed around one core principle — **every concern lives in exactly one place**. 

## The Problem This Solves
Raw data lives in multiple disconnected systems. Business decisions cannot be made from raw, untransformed data scattered across different sources. This pipeline solves that by:
- Centralising data from all sources into one place
- Automating the entire data flow daily without human intervention
- Ensuring data quality through automated testing
- Making the pipeline reproducible by anyone who clones the repository
- Making the infrastructure deployable with a single command

## Architecture Overview
```
Three Data Sources
        ↓
Airbyte Cloud (Ingestion) and Python 
        ↓
Amazon S3 (Data Lake)
        ↓
Snowflake RAW Schema (Loading)
        ↓
dbt Core (Transformation)
        ↓
Snowflake TRANSFORMED Schema (Warehouse)
        ↓
Airflow on VPS (Orchestration)
        ↓
Terraform (Infrastructure as Code)
        ↓
Docker (Containerisation)
        ↓
GitHub (Version Control and CI/CD)
```

### Here is a way to look at it diagrammatically;
<img src="./assets/SupplyChainArch.png" width="600">

## The Data Sources
We ingest from three fundamentally different source types, which demonstrates the pipeline's flexibility:
- Source 1: Amazon S3 Data already lives in S3 in its raw form. Airbyte reads directly from this bucket and moves it into our data lake bucket in an organised structure.
Having studied each, ingestion strategy was that the ingestion code reads it in chunks to keep memory usage flat on the Airflow worker regardless of file size. Each chunk is processed and written to S3 as Parquet before the next chunk is loaded into memory.

- Source 2: PostgreSQL Database A relational database containing structured transactional data. The database credentials are stored securely in AWS Parameter Store, and Airbyte retrieves them at run time. Ingestion strategy - Airbyte Cloud handles the extraction from Postgres and writes the data to S3. Airflow's job is to trigger the sync via the Airbyte API, poll the job status every 30 seconds until it finishes, verify the result using the job ID, and then load the landed data into Snowflake.

- Source 3: Google Sheets Unstructured business data maintained in a spreadsheet. A small reference file,  Python code reads it via the Google Sheets API and writes it to S3 as Parquet.

## Why S3 as the landing zone(Data Lake)

S3 is used as the intermediate landing zone for all three sources before Snowflake loads them. This is a deliberate architectural choice for several reasons.
All data lands in one place first, which makes it easy to inspect, debug, and reprocess if needed. If a Snowflake load fails, the file is still in S3 — we can rerun just the Snowflake task without re-ingesting. S3 handles concurrent writes without issue as long as each source writes to its own prefix, which is enforced by the path structure.

## Why Snowflake as the DataWarehouse
Snowflake separates compute from storage. We only pay for compute when queries are running. Auto suspend set to 60 seconds means the warehouse shuts down when idle. It runs seamlessly with dbt

## The Seven Tables and Loading Strategy
Seven tables total across the three sources. They fall into two categories with different loading strategies:

- Four Static Tables — **Full Refresh Weekly**: These are reference or lookup tables that rarely change. Every time they are loaded we truncate the existing table in Snowflake and reload completely. Because the data is small this is fast and ensures we always have the complete current dataset. These run weekly or on demand.
  
- Three Dynamic Tables — **Incremental Daily**: These tables receive new records every day. We never reload historical data. Every day we load only new records from S3 into a Snowflake staging table and run a MERGE into the final table. MERGE checks each record against a unique key — updates if it exists, inserts if it does not. This keeps performance consistent as data grows.

## Infrastructure-as-code(Terraform)

```
    Postgres 
        │
        │ via Airbyte source connector
        ▼
Source S3 Bucket (raw data)
        │
        │ via Airbyte sync connection
        ▼
Destination S3 Bucket (data lake)        ←── created by S3 module
        │
        │ via Snowflake storage integration
        ▼
Snowflake (database + warehouse)         ←── created by Snowflake module
        │
        │ IAM trust policy connects them
        ▼
Snowflake assumes IAM role → reads from S3 securely
```

- ### S3 Module 
 Creates the destination data lake bucket and the Snowflake IAM role. The IAM role is created with a placeholder trust policy because Snowflake's real IAM user ARN doesn't exist until the Snowflake module runs. The root module patches this afterwards.

- ### Snowflake Module 
  Provisions the Snowflake database, warehouse, and storage integration. It receives the IAM role ARN from the S3 module and uses it to configure the integration. It outputs Snowflake's generated IAM user ARN and external ID back to root so the trust policy can be completed.

- ### Airbyte
  Airbyte Module — Creates the Postgres source connector, the S3 destination connector, and the sync connections between them. It receives all credentials from root via SSM

  ### The Trust Policy: Why It Lives in Root

  ```
  S3 module creates IAM role (placeholder trust policy)
        │
        ▼
  Snowflake module creates storage integration
        │
        │ Snowflake generates:
        │   - storage_aws_iam_user_arn
        │   - storage_aws_external_id
        ▼
  Root module uses BOTH outputs to build the real trust policy
        │
        ▼
  IAM role is patched with the real policy
        │
        ▼
  Snowflake can now assume the role and read from S3
``

### Security Decisions
- All secrets live in AWS SSM Parameter Store, no credentials appear in any .tf file or .tfvars file

- Postgres credentials are fetched from a separate AWS account using a provider alias, not copied or    duplicated

- State is stored in a versioned S3 bucket so any corrupted state can be rolled back

### Bootstrap
```
Bootstrap runs locally (no backend configured)
        │
        │ creates
        ▼
   S3 Bucket
        │
        │ versioning enabled on the bucket
        ▼
Every future Terraform run in the main project
reads and writes its state to this bucket
        │
        ▼
Main project backend.tf points at this exact bucket
        │
        ▼
All module states, resource tracking, and output values
are safely stored and versioned in S3
```
This is the single bucket that becomes the memory of your entire infrastructure. Every resource Terraform has ever created, every output value, every module state — all of it lives here after bootstrap runs. The name is hardcoded deliberately because it must match exactly what the main project's backend configuration points to. Bootstrap is run once and only once at the very beginning of the project.

### Prerequisites
- An AWS account with sufficient IAM permissions
- Access to Admin's AWS account via a configured provider alias (aws.admin_account)
- Terraform installed 
- Snowflake account with credentials ready
- Airbyte Cloud account with a workspace ID
- All SSM parameters pre-populated in AWS Parameter Store under the /supplychain360/ path prefix

### SSM Parameters
This lists every SSM parameter the project expects, because if any one of them is missing, Terraform will fail silently.
```
/supplychain360/db/host
/supplychain360/db/dbname
/supplychain360/db/port
/supplychain360/db/user
/supplychain360/db/password
/supplychain360/airbyte/source_access_key_id
/supplychain360/airbyte/source_secret_access_key
/supplychain360/airbyte/datalake_access_key_id
/supplychain360/airbyte/datalake_secret_access_key
/supplychain360/airbyte/client_id
/supplychain360/airbyte/client_secret
/supplychain360/snowflake/password
```

### How to run it
- Step 1: Run Bootstrap (only once ever)
```
cd bootstrap
terraform init
terraform apply
```
This creates the S3 bucket that stores all future Terraform state. 

- Step 2: Initialize the Main Project
```
cd ..
terraform init
```
Terraform connects to the S3 backend created in Step 1.

- Step 3: Preview the Plan
```
terraform plan
```
Review everything that will be created before committing.

- Step 4: Apply
```
terraform apply
```
Terraform provisions all resources in the correct order — S3 first, Snowflake second, trust policy patch third, Airbyte last.
