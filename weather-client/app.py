iimport requests
import json
import os
from fastapi import FastAPI, Request

app = FastAPI()

@app.get("/")
def index():
    # Get the list of locations from the request body
    locations = request.json()

    # Fetch the weather data for each location
    weather_data = []
    for location in locations:
        url = f"https://api.open-meteo.com/v1/forecast?latitude={location['latitude']}&longitude={location['longitude']}&units=metric"
        response = requests.get(url)
        weather_data.append(response.json())

    # Save the weather data to a JSON file
    with open("weather_data.json", "w") as f:
        json.dump(weather_data, f)

    # Upload the JSON file to a Cloud Storage bucket
    bucket_name = os.environ["BUCKET_NAME"]
    blob = bucket.blob("weather_data.json")
    blob.upload_from_filename("weather_data.json")

    # Publish the endpoint using FastAPI
    return "Weather data fetched and saved successfully!"
