# AWS Serverless User Profile API | Terraform

A serverless REST-style API deployed on AWS using Terraform, demonstrating Infrastructure as Code (IaC), event-driven computing, IAM permissions and NoSQL database integration.

## Project Overview

This project provisions an HTTP API that accepts user profile information, invokes a Python AWS Lambda function, validates the request and stores the resulting record in Amazon DynamoDB.

The infrastructure is defined using Terraform rather than manually configured through the AWS Console.

**Project status:** Successfully deployed and tested. The live API stage and route were subsequently removed to disable public access while preserving the AWS resources and Terraform state.

The repository contains the complete deployable example, including the API route and stage. Deploying this configuration creates a public, unauthenticated endpoint.

## Architecture

```text
Client
  |
  | HTTP POST /users
  v
Amazon API Gateway (HTTP API)
  |
  | Lambda proxy integration
  v
AWS Lambda (Python 3.12)
  |
  | IAM-authorised PutItem
  v
Amazon DynamoDB
  |
  | Partition key: userId (String)
  v
User profile stored
```

## Technology Stack

| Technology | Purpose |
|---|---|
| Terraform | Infrastructure provisioning and lifecycle management |
| API Gateway | HTTP endpoint and Lambda integration |
| AWS Lambda | Python request processing and validation |
| DynamoDB | Serverless NoSQL storage |
| AWS IAM | Least-privilege application permissions |
| AWS CLI / CloudShell | Deployment verification and API testing |

## Infrastructure Components

Terraform provisions:

- DynamoDB table with on-demand billing
- AWS Lambda function using Python 3.12
- IAM execution role and DynamoDB access policy
- API Gateway HTTP API, integration, route and stage
- Lambda invocation permission for API Gateway
- API endpoint output

## Prerequisites

- An AWS account with appropriate permissions
- Terraform installed
- AWS credentials configured securely
- Python 3.12-compatible Lambda source code
- AWS CLI (recommended for verification)

## Deployment

From the project directory:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Review the Terraform plan carefully before approving deployment.

Retrieve the endpoint:

```bash
terraform output -raw api_url
```

The deployment uses the AWS region `eu-north-1`, configured in `main.tf`.

## API Testing

### Successful request

```bash
curl -i -X POST "$(terraform output -raw api_url)" \
  -H "Content-Type: application/json" \
  -d '{"userId":"user-001","name":"Test User"}'
```

**Expected:** HTTP 200 with a confirmation message and the stored item.

A successful request was tested, and the corresponding record was independently retrieved from DynamoDB.

### Input validation

```bash
curl -i -X POST "$(terraform output -raw api_url)" \
  -H "Content-Type: application/json" \
  -d '{"userId":"user-002"}'
```

**Verified:** HTTP 400

```json
{"error":"Valid name is required"}
```

The application rejects requests without required user information.

## Security and Limitations

- Lambda uses an IAM execution role with access scoped to the application's DynamoDB table.
- API Gateway has explicit permission to invoke Lambda.
- The Lambda handler validates required input fields.
- The demonstration API does not implement authentication or authorisation for callers.
- Records with an existing `userId` can be overwritten.
- Input validation is basic and does not impose comprehensive size limits.
- Terraform local state must not be committed to GitHub.
- Synthetic test data should be used; this example is not production-ready.

For the original test deployment, the public API route and stage were removed through Terraform after testing. Subsequent requests returned HTTP 404. Lambda and DynamoDB were preserved.

## Future Improvements

1. Add JWT or IAM-based API authentication.
2. Add request throttling, stricter validation and duplicate-record protection.
3. Configure CloudWatch alarms and structured application logging.
4. Store Terraform state remotely with locking and appropriate access controls.
5. Introduce automated tests and a GitHub Actions CI/CD pipeline.
6. Add cost monitoring and a documented cleanup procedure.

## Learning Outcomes

This project provided hands-on experience in:

- Provisioning connected AWS services using Terraform
- Managing IAM roles and resource-level permissions
- Developing and deploying Python Lambda functions
- Testing HTTP APIs and verifying DynamoDB records
- Troubleshooting provider installations and CloudShell storage
- Reviewing Terraform plans and managing infrastructure changes
- Disabling public API access after completing testing

## Notes

This repository is an educational demonstration of AWS serverless architecture and Infrastructure as Code.

Deployments may incur AWS charges. Review the plan, permissions and expected costs before applying the configuration.
