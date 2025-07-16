import os
import boto3
import csv
import requests
from io import StringIO

s3_client = boto3.client('s3')
bucket_name = os.environ['BUCKET_NAME']
csv_key = "weather_data.csv"

def lambda_handler(event, context):
    api_key = os.environ.get("WEATHER_API_KEY")
    if not api_key:
        raise Exception("Missing WEATHER_API_KEY environment variable")

    city = os.environ.get("WEATHER_CITY", "New York")
    url = f"https://api.openweathermap.org/data/2.5/weather?q={city}&appid={api_key}&units=metric"

    resp = requests.get(url)
    if resp.status_code != 200:
        raise Exception(f"Weather API failed with status {resp.status_code}")

    data = resp.json()

    output = StringIO()
    writer = csv.writer(output)
    writer.writerow(["city", "weather", "temperature_c"])
    writer.writerow([
        city,
        data["weather"][0]["description"],
        data["main"]["temp"]
    ])

    s3_client.put_object(
        Bucket=bucket_name,
        Key=csv_key,
        Body=output.getvalue()
    )

    return {
        'statusCode': 200,
        'body': 'Weather data refreshed and saved to S3'
    }
