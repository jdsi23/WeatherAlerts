import os
from weather_fetcher import WeatherFetcher

def main():
    city = os.environ.get("WEATHER_CITY", "New York")  # Default city if none provided
    try:
        weather_fetcher = WeatherFetcher()
        weather_data = weather_fetcher.get_weather(city)
        if weather_data:
            print(f"Weather in {city}: {weather_data['weather'][0]['description'].capitalize()}, "
                  f"Temp: {weather_data['main']['temp']}°C")
        else:
            print("Failed to retrieve weather data.")
    except Exception as e:
        print(f"Application error: {e}")

if __name__ == "__main__":
    main()
