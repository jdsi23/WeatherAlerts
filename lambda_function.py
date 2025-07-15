import os
import json
import boto3
import requests
from datetime import datetime
from dotenv import load_dotenv

s3 = boto3.client('s3')

def lambda_handler(event, context):
    api_key = os.environ['WEATHER_API_KEY']  # Correct env var key
    if not api_key:
        return {
            'statusCode': 500,
            'body': json.dumps("API key is not set in environment variables.")
        }
    bucket_name = os.environ['S3_BUCKET_NAME']
    
    city = "Tampa"
    url = f"https://api.weatherapi.com/v1/current.json?key={api_key}&q={city}"

    try:
        response = requests.get(url)
        response.raise_for_status()
        weather_data = response.json()

        timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H-%M-%SZ")
        filename = f"weather_{city.replace(' ', '_')}_{timestamp}.json"

        s3.put_object(
            Bucket=bucket_name,
            Key=filename,
            Body=json.dumps(weather_data),
            ContentType='application/json'
        )
        
        print(f"Successfully saved weather data as {filename}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(f"Weather data saved as {filename}")
        }
    except Exception as e:
        print(f"Error fetching or uploading weather data: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error fetching or uploading weather data: {str(e)}")
        }
