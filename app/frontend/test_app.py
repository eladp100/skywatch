from app import app


def test_unsupported_city():
    client = app.test_client()

    response = client.get("/weather/london")

    assert response.status_code == 404
    assert response.get_json() == {
        "error": "City not supported yet"
    }