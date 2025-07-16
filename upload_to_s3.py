import boto3
import os
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
load_dotenv()

# Get credentials and bucket info from .env
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_REGION = os.getenv("AWS_REGION")
BUCKET_NAME = os.getenv("S3_BUCKET_NAME")

def upload_file_to_s3(local_file_path):
    try:
        s3 = boto3.client(
            "s3",
            aws_access_key_id=AWS_ACCESS_KEY,
            aws_secret_access_key=AWS_SECRET_KEY,
            region_name=AWS_REGION
        )

        local_file_path = Path(local_file_path).resolve()
        s3_key = local_file_path.name  # just the filename, not full path
        s3.upload_file(str(local_file_path), BUCKET_NAME, s3_key)
        print(f"✅ Uploaded {s3_key} to s3://{BUCKET_NAME}/{s3_key}")
    except Exception as e:
        print(f"❌ Upload failed: {e}")
