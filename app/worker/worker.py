import requests


def fetch_weather():
    url = "https://api.open-meteo.com/v1/forecast"

    params = {
        "latitude": 32.0853,
        "longitude": 34.7818,
        "current": "temperature_2m",
    }

    response = requests.get(url, params=params, timeout=10)
    response.raise_for_status()

    data = response.json()
    temperature = data["current"]["temperature_2m"]

    print(f"Current temperature in Tel Aviv: {temperature} C")


def main():
    print("SkyWatch Worker started!")
    fetch_weather()


if __name__ == "__main__":
    main()