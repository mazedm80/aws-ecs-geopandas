# AWS ECR ECS Geospatial Processing Demo
This project demonstrates a scalable, serverless, event-driven geospatial data processing workflow on AWS. Leveraging services such as Amazon ECR, ECS, and EventBridge, the solution efficiently processes daily wind speed data for Germany. The processed results are stored as GeoParquet files using Rasterio and GeoPandas. By utilizing a serverless architecture, the workflow optimizes resource usage and minimizes AWS operational costs.

This project includes the following components:
- Python scripts for data processing
  - `rasterio` and `geopandas`: Libraries for geospatial data manipulation
- Dockerfiles for containerization
- AWS IAM user for GitHub Actions with appropriate permissions
- AWS ECR for container image storage
- AWS ECS Service and Task Definitions for running the containers
  - Fargate launch type for serverless container management
  - IAM roles with least privilege access
  - CloudWatch Logs for monitoring and logging
- AWS S3 bucket for storing output data
- AWS EventBridge for scheduling the ECS tasks
- GitHub Actions workflows for CI/CD
  - Trigger on PR merge to `main`
  - Python code linting and formatting
  - Docker image building
  - Build and push Docker images to ECR

## Project Structure
```
├── Dockerfile
├── LICENSE
├── README.md
├── pyproject.toml
├── requirements.txt
├── requirements_dev.txt
├── src
│   └── main.py
└── terraform
    ├── environments
    │   └── dev.tfvars
    ├── main.tf
    ├── modules
    │   ├── ecr
    │   │   └── main.tf
    │   ├── ecs
    │   │   ├── iam.tf
    │   │   └── main.tf
    │   ├── eventbridge
    │   │   ├── iam.tf
    │   │   └── main.tf
    │   ├── iam
    │   │   └── main.tf
    │   └── s3
    │       └── main.tf
    ├── terraform.tfstate
    ├── terraform.tfstate.backup
    └── variables.tf
```

## Data Sources
1. GADM (Global Administrative Areas) for administrative boundaries [link](https://gwa.cdn.nazkamapps.com/country_tifs_v4/gadm41_DEU_4.json)
2. UC Davis for wind speed data [link](https://geodata.ucdavis.edu/gadm/gadm4.1/json/DEU_wind-speed_10m.tif)