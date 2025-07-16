import requests
import os
import csv
import boto3
from io import StringIO
from datetime import datetime

# === Load Lambda Environment Vars ===
API_KEY = os.getenv("OPENWEATHER_API_KEY")
CITY = os.getenv("CITY", "Tampa,US")
UNITS = "imperial"
BUCKET_NAME = os.getenv("S3_BUCKET_NAME")
S3_KEY = os.getenv("S3_KEY", "weather_data.csv")

# === Fetch Weather ===
def fetch_weather(city):
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "q": city,
        "appid": API_KEY,
        "units": UNITS,
        "lang": "en"
    }

    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        data = response.json()
        return {
            "timestamp": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"),
            "city": city,
            "temperature": data["main"]["temp"],
            "humidity": data["main"]["humidity"],
            "wind_speed": data["wind"]["speed"],
            "weather": data["weather"][0]["description"]
        }
    except Exception as e:
        print(f"❌ Error fetching weather: {e}")
        return None

# === Append Row to CSV in S3 ===
def append_to_s3_csv(data, bucket, key):
    s3 = boto3.client("s3")

    try:
        existing_csv = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8")
        lines = existing_csv.strip().split("\n")
    except s3.exceptions.NoSuchKey:
        lines = ["timestamp,city,temperature,humidity,wind_speed,weather"]

    row = ",".join([str(data[col]) for col in data])
    lines.append(row)

    updated_csv = "\n".join(lines)
    s3.put_object(Bucket=bucket, Key=key, Body=updated_csv.encode("utf-8"))
    print(f"✅ Uploaded updated CSV to s3://{bucket}/{key}")

# === Lambda Entry Point ===
def lambda_handler(event, context):
    print("📡 Fetching weather data...")
    weather_data = fetch_weather(CITY)
    if weather_data:
        append_to_s3_csv(weather_data, BUCKET_NAME, S3_KEY)
