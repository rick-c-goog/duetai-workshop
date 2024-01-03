/*
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.example.cloudrun;

// [START eventarc_storage_cloudevent_handler]
import com.google.events.cloud.storage.v1.StorageObjectData;
import com.google.protobuf.InvalidProtocolBufferException;
import com.google.protobuf.Timestamp;
import com.google.protobuf.util.JsonFormat;
import io.cloudevents.CloudEvent;
import com.google.protobuf.LazyStringArrayList;

import java.io.IOException;
// import java.sql.Blob;
import java.time.Instant;

import javax.smartcardio.ResponseAPDU;

import com.google.cloud.bigquery.BigQuery;
import com.google.cloud.bigquery.BigQueryException;
import com.google.cloud.bigquery.BigQueryOptions;
import com.google.cloud.bigquery.FormatOptions;
import com.google.cloud.bigquery.Job;
import com.google.cloud.bigquery.JobInfo;
import com.google.cloud.bigquery.JobInfo.SchemaUpdateOption;
import com.google.cloud.bigquery.JobInfo.WriteDisposition;
import com.google.cloud.bigquery.LoadJobConfiguration;
import com.google.cloud.bigquery.TableId;
import com.google.cloud.storage.Blob;
import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import java.io.IOException;
import java.util.UUID;

import com.google.api.core.ApiFuture;
import com.google.api.core.ApiFutureCallback;
import com.google.api.core.ApiFutures;
import com.google.api.gax.rpc.ApiException;
import com.google.cloud.pubsub.v1.Publisher;
import com.google.common.util.concurrent.MoreExecutors;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.PubsubMessage;
import com.google.pubsub.v1.TopicName;
import com.google.pubsub.v1.ProjectTopicName;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.TimeUnit;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CloudEventController {

  @RequestMapping(value = "/", method = RequestMethod.POST, consumes = "application/json")
  ResponseEntity<String> handleCloudEvent(@RequestBody CloudEvent cloudEvent)
      throws InvalidProtocolBufferException {

    // CloudEvent information
    System.out.println("Id: " + cloudEvent.getId());
    System.out.println("Source: " + cloudEvent.getSource());
    System.out.println("Type: " + cloudEvent.getType());
    System.out.println("Data String: " + cloudEvent.getData().toBytes());

    String json = new String(cloudEvent.getData().toBytes());
    System.out.println("json format of the cloud event" +json);
    StorageObjectData.Builder builder = StorageObjectData.newBuilder();
    JsonFormat.parser().merge(json, builder);
    StorageObjectData data = builder.build();

    // Convert protobuf timestamp to java Instant
    Timestamp ts = data.getUpdated();
    Instant updated = Instant.ofEpochSecond(ts.getSeconds(), ts.getNanos());
    String msg =
        String.format(
            "Cloud Storage object changed: %s/%s modified at %s\n",
            data.getBucket(), data.getName(), updated);

    System.out.println(msg);
    
    // Commit the file to the BigQuery

     // Get the Cloud Storage event data from the Cloud Functions event context.
    // StorageObjectData data = context.dataAs(StorageObjectData.class);
    String bucketName = data.getBucket();
    String objectName = data.getName();
    String sourceUri = "gs://" + bucketName + "/" + objectName;

    // Get the Cloud Storage object from the bucket.
    Storage storage = StorageOptions.getDefaultInstance().getService();
    Blob blob = storage.get(BlobId.of(bucketName, objectName));

    // Load the JSON objects from the file.
    // ...

    // Batch insert the JSON objects into the BigQuery table.
    try {
      // Initialize client that will be used to send requests. This client only needs to be created
      // once, and can be reused for multiple requests.
      BigQuery bigquery = BigQueryOptions.getDefaultInstance().getService();

      TableId tableId = TableId.of("weatherDataset", "weather-table4");

      // Skip header row in the file.
      LoadJobConfiguration loadConfig =
          LoadJobConfiguration.newBuilder(tableId, sourceUri)
              .setFormatOptions(FormatOptions.json())
              .setAutodetect(true)
              .setWriteDisposition(WriteDisposition.WRITE_TRUNCATE)
              .build();

      // Load data from a GCS JSON file into the table
      Job job = bigquery.create(JobInfo.of(loadConfig));
      // Blocks until this load table job completes its execution, either failing or succeeding.
      job = job.waitFor();
      if (job.isDone()) {
        System.out.println("Json from GCS successfully added during load append job");
      } else {
        System.out.println(
            "BigQuery was unable to load into the table due to an error:"
                + job.getStatus().getError());
      }
    } catch (BigQueryException | InterruptedException e) {
      System.out.println("Column not added during load append \n" + e.toString());
    }

    // Publish message to Cloud pubsub

    String projectId = System.getenv("PROJECT_ID");
    String topicId = System.getenv("TOPIC_ID");
    System.out.println("Project ID: " + projectId+ "; TopicID:"+topicId);
    ProjectTopicName topicName = ProjectTopicName.of(projectId, topicId);
    Publisher publisher = null;
    
    try {
      // Create a publisher instance with default settings bound to the topic
      publisher = Publisher.newBuilder(
                  topicName)
                  .build();

      String message = "first message received";

      ByteString dataByte = ByteString.copyFromUtf8(message);
      PubsubMessage pubsubMessage = PubsubMessage.newBuilder().setData(dataByte).build();

        // Once published, returns a server-assigned message id (unique within the topic)
        ApiFuture<String> future = publisher.publish(pubsubMessage);

        // Add an asynchronous callback to handle success / failure
        ApiFutures.addCallback(
            future,
            new ApiFutureCallback<String>() {

              @Override
              public void onFailure(Throwable throwable) {
                if (throwable instanceof ApiException) {
                  ApiException apiException = ((ApiException) throwable);
                  // details on the API exception
                  System.out.println(apiException.getStatusCode().getCode());
                  System.out.println(apiException.isRetryable());
                }
                System.out.println("Error publishing message : " + message);
              }

              @Override
              public void onSuccess(String messageId) {
                // Once published, returns server-assigned message ids (unique within the topic)
                System.out.println("Published message ID: " + messageId);
              }
            },
            MoreExecutors.directExecutor());

    } catch( java.io.IOException e) {
      System.out.println("Could not Publish to Cloud PubSub \n" + e.toString());
    }

    try {
      if (publisher != null) {
        // When finished with the publisher, shutdown to free up resources.
        publisher.shutdown();
        publisher.awaitTermination(1, TimeUnit.MINUTES);
      } 
    }catch ( java.lang.InterruptedException e){
       System.out.println("Could not shutdown the Publisher \n" + e.toString());
    }


    return ResponseEntity.ok().body(msg);
  }

  // Handle exceptions from CloudEvent Message Converter
  @ExceptionHandler(IllegalStateException.class)
  @ResponseStatus(value = HttpStatus.BAD_REQUEST, reason = "Invalid CloudEvent received")
  public void noop() {
    return;
  }


}
// [END eventarc_storage_cloudevent_handler]