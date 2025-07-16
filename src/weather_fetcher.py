import os
import requests

class WeatherFetcher:
    def __init__(self, api_key=None, base_url=None):
        self.api_key = api_key or os.environ.get("WEATHER_API_KEY")
        if not self.api_key:
            raise ValueError("Missing WEATHER_API_KEY environment variable")

        # Allow base URL override or default to openweathermap.org example API
        self.base_url = base_url or os.environ.get(
            "WEATHER_API_BASE_URL",
            "https://api.openweathermap.org/data/2.5/weather"
        )

    def get_weather(self, city):
        params = {
            "q": city,
            "appid": self.api_key,
            "units": "metric"
        }
        try:
            response = requests.get(self.base_url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            return data
        except requests.RequestException as e:
            print(f"Error fetching weather data: {e}")
            return None
