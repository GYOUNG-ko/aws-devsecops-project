package com.gyoung.pms.patch;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Instant;
import java.util.Map;

import com.gyoung.pms.config.PmsS3Properties;
import com.gyoung.pms.support.FakeS3Client;
import org.junit.jupiter.api.Test;

import software.amazon.awssdk.services.s3.model.HeadObjectResponse;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Response;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.S3Object;

class PatchServiceTest {

    private static final PmsS3Properties PROPERTIES = new PmsS3Properties("private-pms-bucket", "patches/");

    @Test
    void listsPatchObjectsUsingProductVersionAndFilenameFromTheKey() {
        var object = S3Object.builder()
                .key("patches/spider-tm/5.5.1/spider-tm-5.5.1.tar.gz")
                .size(123456L)
                .lastModified(Instant.parse("2026-09-15T00:00:00Z"))
                .build();
        var service = new PatchService(
                FakeS3Client.create(request -> ListObjectsV2Response.builder().contents(object).build(), request -> null),
                PROPERTIES);

        var patches = service.listPatches();

        assertThat(patches).containsExactly(new PatchObject(
                "spider-tm", "5.5.1", "spider-tm-5.5.1.tar.gz", object.key(), 123456L,
                Instant.parse("2026-09-15T00:00:00Z"), null));
    }

    @Test
    void returnsHeadObjectMetadataAndChecksum() {
        var service = new PatchService(FakeS3Client.create(
                request -> ListObjectsV2Response.builder().build(),
                request -> HeadObjectResponse.builder()
                        .contentLength(123456L)
                        .lastModified(Instant.parse("2026-09-15T00:00:00Z"))
                        .metadata(Map.of("sha256", "a".repeat(64)))
                        .build()), PROPERTIES);

        var patch = service.getMetadata("patches/spider-tm/5.5.1/spider-tm-5.5.1.tar.gz");

        assertThat(patch.checksum()).isEqualTo("a".repeat(64));
        assertThat(patch.size()).isEqualTo(123456L);
    }

    @Test
    void rejectsKeysOutsideThePatchPrefixBeforeCallingS3() {
        var service = new PatchService(FakeS3Client.create(request -> null, request -> null), PROPERTIES);

        assertThatThrownBy(() -> service.getMetadata("private/secret.txt"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void mapsNoSuchKeyToNotFound() {
        var service = new PatchService(FakeS3Client.create(
                request -> ListObjectsV2Response.builder().build(),
                request -> { throw NoSuchKeyException.builder().statusCode(404).build(); }), PROPERTIES);

        assertThatThrownBy(() -> service.getMetadata("patches/spider-tm/5.5.1/missing.tar.gz"))
                .isInstanceOf(PatchNotFoundException.class);
    }
}
