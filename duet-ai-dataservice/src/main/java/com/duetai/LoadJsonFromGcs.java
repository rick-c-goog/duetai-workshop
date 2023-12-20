import com.google.api.gax.rpc.ApiException;
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
import com.google.cloud.functions.Context;
import com.google.cloud.functions.RawBackgroundFunction;
import com.google.cloud.storage.Blob;
import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import java.io.IOException;
import java.util.UUID;

public class LoadJsonFromGcs implements RawBackgroundFunction {

  @Override
  public void accept(String json, Context context) {
    // Get the Cloud Storage event data from the Cloud Functions event context.
    StorageObjectData data = context.dataAs(StorageObjectData.class);
    String bucketName = data.getBucket();
    String objectName = data.getName();

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

      TableId tableId = TableId.of("my-dataset", "my-table");

      // Skip header row in the file.
      LoadJobConfiguration loadConfig =
          LoadJobConfiguration.newBuilder(tableId, blob.getContent())
              .setFormatOptions(FormatOptions.json())
              .setSchemaUpdateOptions(SchemaUpdateOption.ALLOW_FIELD_ADDITION)
              .setWriteDisposition(WriteDisposition.WRITE_TRUNCATE)
              .setSkipLeadingRows(1)
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
    } catch (BigQueryException | InterruptedException | IOException e) {
      System.out.println("Column not added during load append \n" + e.toString());
    }
  }

  // Class to hold the Cloud Storage event data.
  private static class StorageObjectData {

    private String bucket;
    private String name;

    public String getBucket() {
      return bucket;
    }

    public void setBucket(String bucket) {
      this.bucket = bucket;
    }

    public String getName() {
      return name;
    }

    public void setName(String name) {
      this.name = name;
    }
  }
}
