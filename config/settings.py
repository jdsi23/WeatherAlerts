import os
from dotenv import load_dotenv

load_dotenv()  # Load from .env in local development

WEATHER_API_KEY = os.getenv("WEATHER_API_KEY")
WEATHER_API_BASE_URL = os.getenv(
    "WEATHER_API_BASE_URL",
    "https://api.openweathermap.org/data/2.5/weather"
)
WEATHER_CITY = os.getenv("WEATHER_CITY", "New York")

if not WEATHER_API_KEY:
    raise EnvironmentError("Missing WEATHER_API_KEY environment variable")
