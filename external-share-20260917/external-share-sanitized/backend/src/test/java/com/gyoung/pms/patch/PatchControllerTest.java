package com.gyoung.pms.patch;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Instant;

import com.gyoung.pms.config.PmsS3Properties;
import com.gyoung.pms.support.FakeS3Client;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import software.amazon.awssdk.services.s3.model.HeadObjectResponse;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Response;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.S3Object;
import software.amazon.awssdk.core.exception.SdkClientException;

class PatchControllerTest {

    @Test
    void exposesThePatchListContract() {
        var controller = new PatchController(service());

        var response = controller.listPatches();

        assertThat(response).hasSize(1);
        assertThat(response.getFirst().product()).isEqualTo("spider-tm");
        assertThat(response.getFirst().checksum()).isNull();
    }

    @Test
    void mapsAStorageNotFoundToASafeHttpResponse() {
        var controller = new PatchController(service());
        var handler = new S3ExceptionHandler();

        assertThatThrownBy(() -> controller.getMetadata("patches/spider-tm/5.5.1/missing.tar.gz"))
                .isInstanceOf(PatchNotFoundException.class);

        var response = handler.notFound(new PatchNotFoundException("patches/spider-tm/5.5.1/missing.tar.gz"));
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).containsEntry("code", "PATCH_NOT_FOUND");
    }

    @Test
    void mapsClientCredentialFailuresToASafeGatewayResponse() {
        var response = new S3ExceptionHandler().s3ClientFailure(SdkClientException.create("credential lookup failed"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_GATEWAY);
        assertThat(response.getBody()).containsEntry("code", "PATCH_STORAGE_UNAVAILABLE");
    }

    private PatchService service() {
        var s3Client = FakeS3Client.create(
                request -> ListObjectsV2Response.builder().contents(S3Object.builder()
                        .key("patches/spider-tm/5.5.1/spider-tm-5.5.1.tar.gz")
                        .size(123456L)
                        .lastModified(Instant.parse("2026-09-15T00:00:00Z"))
                        .build()).build(),
                request -> {
                    if (request.key().endsWith("missing.tar.gz")) {
                        throw NoSuchKeyException.builder().statusCode(404).build();
                    }
                    return HeadObjectResponse.builder().build();
                });
        return new PatchService(s3Client, new PmsS3Properties("private-pms-bucket", "patches/"));
    }
}
