import requests
import json
import os

from google.cloud import storage

def weather_to_gcs((event, context):
        api_key = os.environ['API_KEY']
        bucket_name = os.environ['BUCKET_NAME']
        api_url=os.environ['API_URL']
        destination_blob_name = "weather_data.json"
        place = 'New York City,us'
        url = f'{api_url}?q={place}&appid={api_key}'

        response = requests.get(url)

        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(destination_blob_name)

        if response.status_code == 200:
            weather_data = response.json()
            print(weather_data)
            # Save the weather data to a JSON file
            with open("weather_data.json", "w") as f:
                json.dump(weather_data, f)

            # Upload the JSON file to the blob
            blob.upload_from_filename("weather_data.json")

        else:
            print("Error fetching weather data")

        # Return a success message
        return "Weather data fetched and saved successfully!"
