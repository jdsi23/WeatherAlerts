# Use official lightweight Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src ./src
COPY config ./config

# Set environment variables (can be overridden by ECS task)
ENV WEATHER_CITY="New York"

# Run the main app
CMD ["python", "src/main.py"]
