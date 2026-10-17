from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from SkyWatch!"

@app.route("/weather/<city>")
def weather(city):
    return jsonify({
        "city": city,
        "temperature": 25,
        "condition": "Sunny"
    })

if __name__ == "__main__":
    app.run(debug=True)