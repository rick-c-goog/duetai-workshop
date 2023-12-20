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
import org.junit.Test;

public class LoadJsonFromGcsTest {

  @Test
  public void testAccept() {
    // Create a mock context.
    Context context = new Context() {
      @Override
      public String eventType() {
        return "google.cloud.storage.object.v1.finalized";
      }

      @Override
      public String resource() {
        return "projects/_/buckets/my-bucket/objects/my-object";
      }

      @Override
      public String timestamp() {
        return "2023-03-08T12:00:00Z";
      }

      @Override
      public String eventId() {
        return UUID.randomUUID().toString();
      }
    };

    // Create a mock storage object.
    Blob blob = new Blob() {
      @Override
      public String getBucket() {
        return "my-bucket";
      }

      @Override
      public String getName() {
        return "my-object";
      }

      @Override
      public byte[] getContent() {
        return new byte[0];
      }
    };

    // Create a mock storage service.
    Storage storage = new Storage() {
      @Override
      public Blob get(BlobId blobId) {
        return blob;
      }
    };

    // Create a mock bigquery service.
    BigQuery bigquery = new BigQuery() {
      @Override
      public Job create(JobInfo jobInfo) {
        return new Job() {
          @Override
          public boolean isDone() {
            return true;
          }

          @Override
          public Status getStatus() {
            return new Status() {
              @Override
              public boolean getSuccess() {
                return true;
              }
            };
          }
        };
      }
    };

    // Create a mock load job configuration.
    LoadJobConfiguration loadConfig =
        LoadJobConfiguration.newBuilder(TableId.of("my-dataset", "my-table"), blob.getContent())
            .setFormatOptions(FormatOptions.json())
            .setSchemaUpdateOptions(SchemaUpdateOption.ALLOW_FIELD_ADDITION)
            .setWriteDisposition(WriteDisposition.WRITE_TRUNCATE)
            .setSkipLeadingRows(1)
            .build();

    // Create a mock raw background function.
    RawBackgroundFunction function = new LoadJsonFromGcs();

    // Call the accept() method.
    function.accept(null, context);

    // Verify that the load job was created correctly.
    Job job = bigquery.getJob(JobId.of(UUID.randomUUID().toString()));
    assertEquals(loadConfig, job.getConfiguration());
  }

  @Test
  public void testAcceptWithException() {
    // Create a mock context.
    Context context = new Context() {
      @Override
      public String eventType() {
        return "google.cloud.storage.object.v1.finalized";
      }

      @Override
      public String resource() {
        return "projects/_/buckets/my-bucket/objects/my-object";
      }

      @Override
      public String timestamp() {
        return "2023-03-08T12:00:00Z";
      }

      @Override
      public String eventId() {
        return UUID.randomUUID().toString();
      }
    };

    // Create a mock storage object.
    Blob blob = new Blob() {
      @Override
      public String getBucket() {
        return "my-bucket";
      }

      @Override
      public String getName() {
        return "my-object";
      }

      @Override
      public byte[] getContent() {
        return new byte[0];
      }
    };

    // Create a mock storage service.
    Storage storage = new Storage() {
      @Override
      public Blob get(BlobId blobId) {
        return blob;
      }
    };

    // Create a mock bigquery service.
    BigQuery bigquery = new BigQuery() {
      @Override
      public Job create(JobInfo jobInfo) {
        throw new BigQueryException("Error creating load job");
      }
    };

    // Create a mock load job configuration.
    LoadJobConfiguration loadConfig =
        LoadJobConfiguration.newBuilder(TableId.of("my-dataset", "my-table"), blob.getContent())
            .setFormatOptions(FormatOptions.json())
            .setSchemaUpdateOptions(SchemaUpdateOption.ALLOW_FIELD_ADDITION)
            .setWriteDisposition(WriteDisposition.WRITE_TRUNCATE)
            .setSkipLeadingRows(1)
            .build();

    // Create a mock raw background function.
    RawBackgroundFunction function = new LoadJsonFromGcs();

    // Call the accept() method.
    function.accept(null, context);

    // Verify that the load job was not created.
    Job job = bigquery.getJob(JobId.of(UUID.randomUUID().toString()));
    assertNull(job);
  }
}
