
import json
import os

import pika
import requests


RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "localhost")
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
RABBITMQ_PASSWORD = os.getenv("RABBITMQ_PASSWORD", "guest")
QUEUE_NAME = "weather_tasks"

CITIES = {
    "tel-aviv": {
        "latitude": 32.0853,
        "longitude": 34.7818,
    },
    "jerusalem": {
        "latitude": 31.7683,
        "longitude": 35.2137,
    },
}


def fetch_weather(city):
    coordinates = CITIES[city]

    url = "https://api.open-meteo.com/v1/forecast"

    params = {
        "latitude": coordinates["latitude"],
        "longitude": coordinates["longitude"],
        "current": "temperature_2m",
    }

    response = requests.get(url, params=params, timeout=10)
    response.raise_for_status()

    data = response.json()
    temperature = data["current"]["temperature_2m"]

    print(f"Current temperature in {city}: {temperature} C")


def process_message(channel, method, properties, body):
    try:
        message = json.loads(body.decode("utf-8"))
        city = message["city"]

        if city not in CITIES:
            raise ValueError(f"Unsupported city: {city}")

        print(f"Received weather task for city: {city}")

        fetch_weather(city)

        channel.basic_ack(
            delivery_tag=method.delivery_tag
        )

        print("Task completed successfully! Message ACK sent.")

    except (json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
        print(f"Invalid message: {error}")

        channel.basic_nack(
            delivery_tag=method.delivery_tag,
            requeue=False
        )

    except requests.exceptions.RequestException as error:
        print(f"Failed to fetch weather: {error}")

        channel.basic_nack(
            delivery_tag=method.delivery_tag,
            requeue=True
        )

        print("Message returned to queue for retry.")


def connect_to_rabbitmq():
    credentials = pika.PlainCredentials(
        RABBITMQ_USER,
        RABBITMQ_PASSWORD
    )

    connection = pika.BlockingConnection(
        pika.ConnectionParameters(
            host=RABBITMQ_HOST,
            credentials=credentials,
            heartbeat=60,
        )
    )

    try:
        print("Connected to RabbitMQ successfully!")

        channel = connection.channel()

        channel.queue_declare(
            queue=QUEUE_NAME,
            durable=True
        )

        channel.basic_qos(prefetch_count=1)

        channel.basic_consume(
            queue=QUEUE_NAME,
            on_message_callback=process_message,
            auto_ack=False
        )

        print("Waiting for weather tasks. Press Ctrl+C to stop.")

        channel.start_consuming()

    except KeyboardInterrupt:
        print("\nStopping SkyWatch Worker...")

        if channel.is_open:
            channel.stop_consuming()

    finally:
        if connection.is_open:
            connection.close()

        print("RabbitMQ connection closed.")


def main():
    print("SkyWatch Worker started!")

    try:
        connect_to_rabbitmq()

    except pika.exceptions.AMQPError as error:
        print(f"RabbitMQ error: {error}")


if __name__ == "__main__":
    main()
