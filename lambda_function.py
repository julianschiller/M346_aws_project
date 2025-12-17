import json
import boto3
import uuid
import os
from datetime import datetime

# Verwende Environment Variable aus Terraform
TABLE_NAME = os.environ.get("TABLE_NAME", "Notes")
dynamodb = boto3.client('dynamodb')

def create_new_note(event, context):
    try: 
        body = json.loads(event.get("body", "{}"))
        note_id = str(uuid.uuid4())
        title = body.get("title", "")
        text = body.get("text", "")
        created_time = datetime.utcnow().isoformat()
        
        dynamodb.put_item(
            TableName=TABLE_NAME,
            Item={
                "id": {"S": note_id},
                "title": {"S": title},
                "text": {"S": text},
                "created_time": {"S": created_time}
            }
        )
        
        return {
            "statusCode": 200,
            "body": json.dumps({"id": note_id})
        }
    
    except Exception as e:
        print(f"Error in create_new_note: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

def get_all_notes(event, context):
    try:
        response = dynamodb.scan(TableName=TABLE_NAME)
        items = response.get('Items', [])
        
        # Convert DynamoDB format to regular JSON
        notes = []
        for item in items:
            notes.append({
                "id": item.get("id", {}).get("S", ""),
                "title": item.get("title", {}).get("S", ""),
                "text": item.get("text", {}).get("S", ""),
                "created_time": item.get("created_time", {}).get("S", "")
            })
        
        return {
            "statusCode": 200,
            "body": json.dumps({"notes": notes})
        }
    except Exception as e:
        print(f"Error in get_all_notes: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    # API Gateway v2 Format
    route_key = event.get("routeKey", "")
    
    # Parse route and method from routeKey (z.B. "GET /note")
    if " " in route_key:
        method, route = route_key.split(" ", 1)
    else:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid route"})
        }
    
    if route == "/note" and method == "GET":
        return get_all_notes(event, context)
    
    if route == "/note" and method == "POST":
        return create_new_note(event, context)
    
    return {
        "statusCode": 404,
        "body": json.dumps({"error": "Route not found"})
    }