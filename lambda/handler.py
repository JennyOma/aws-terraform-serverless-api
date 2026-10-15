import json
import os
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    try:
        # Read the JSON request from API Gateway
        body = json.loads(event.get("body") or "{}")

        user_id = body.get("userId")
        name = body.get("name")

        # Validate the input
        if not isinstance(user_id, str) or not user_id.strip():
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Valid userId is required"})
            }

        if not isinstance(name, str) or not name.strip():
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Valid name is required"})
            }

        # Create the DynamoDB record
        item = {
            "userId": user_id.strip(),
            "name": name.strip(),
            "source": "API Gateway"
        }

        table.put_item(Item=item)

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "User written to DynamoDB",
                "item": item
            })
        }

    except (json.JSONDecodeError, TypeError, AttributeError):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid JSON request"})
        }
