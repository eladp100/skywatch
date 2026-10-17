import requests
from flask import Flask, jsonify

app = Flask(__name__)

CITIES = {
    "tel-aviv": {
        "latitude": 32.08,
        "longitude": 34.78
    },
    "jerusalem": {
        "latitude": 31.77,
        "longitude": 35.21
    }
}


@app.route("/")
def home():
    return "Hello from SkyWatch!"


@app.route("/weather/<city>")
def weather(city):
    city_key = city.lower()

    if city_key not in CITIES:
        return jsonify({"error": "City not supported yet"}), 404

    url = "https://api.open-meteo.com/v1/forecast"

    params = {
        "latitude": CITIES[city_key]["latitude"],
        "longitude": CITIES[city_key]["longitude"],
        "current": "temperature_2m"
    }

    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()

        data = response.json()
        temperature = data["current"]["temperature_2m"]

        return jsonify({
            "city": city,
            "temperature": temperature,
            "unit": "C"
        })

    except (requests.RequestException, KeyError, ValueError):
        return jsonify({"error": "Weather service unavailable"}), 502


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)