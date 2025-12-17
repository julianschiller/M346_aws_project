import json
import boto3
import uuid
from datetime import datetime

TABLE_NAME = "notes"

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
        return {
            "statusCode": 500,
            "body": json.dumps({"error:" + str(e)})
        }

def get_all_notes(event, context):
    try:
        response = dynamodb.scan(
            TableName=TABLE_NAME
        )
        
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
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

def lambda_handler(event, context):
    route = event["resource"]
    method = event["httpMethod"]

    body = json.loads(event["body"])

    if route == "/note" and method == "GET":
        return get_all_notes(event)
    
    if route == "/note" and method == "POST":
        return create_new_note(event)