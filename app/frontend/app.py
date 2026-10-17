import requests
from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def home():
    return "Hello from SkyWatch!"


@app.route("/weather/<city>")
def weather(city):
    if city.lower() != "tel-aviv":
        return jsonify({"error": "City not supported yet"}), 404

    url = "https://api.open-meteo.com/v1/forecast"

    params = {
        "latitude": 32.08,
        "longitude": 34.78,
        "current": "temperature_2m"
    }

    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()

        data = response.json()
        temperature = data["current"]["temperature_2m"]

        return jsonify({
            "city": "Tel-Aviv",
            "temperature": temperature,
            "unit": "C"
        })

    except (requests.RequestException, KeyError, ValueError):
        return jsonify({"error": "Weather service unavailable"}), 502


if __name__ == "__main__":
    app.run(debug=True)