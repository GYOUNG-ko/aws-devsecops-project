package com.gyoung.pms.patch;

import java.util.List;
import java.util.Map;

import com.gyoung.pms.config.PmsS3Properties;
import org.springframework.stereotype.Service;

import software.amazon.awssdk.awscore.exception.AwsServiceException;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Request;
import software.amazon.awssdk.services.s3.model.S3Object;

@Service
public class PatchService {

    private final S3Client s3Client;
    private final PmsS3Properties properties;

    public PatchService(S3Client s3Client, PmsS3Properties properties) {
        this.s3Client = s3Client;
        this.properties = properties;
    }

    public List<PatchObject> listPatches() {
        try {
            return s3Client.listObjectsV2(ListObjectsV2Request.builder()
                            .bucket(properties.bucket())
                            .prefix(properties.prefix())
                            .build())
                    .contents()
                    .stream()
                    .filter(object -> !object.key().endsWith("/"))
                    .map(this::fromListObject)
                    .toList();
        } catch (AwsServiceException exception) {
            throw mapS3Exception(exception, properties.prefix());
        }
    }

    public PatchObject getMetadata(String key) {
        validateKey(key);
        try {
            var response = s3Client.headObject(HeadObjectRequest.builder()
                    .bucket(properties.bucket())
                    .key(key)
                    .build());
            var fields = PatchKey.parse(key, properties.prefix());
            return new PatchObject(
                    fields.product(), fields.version(), fields.fileName(), key,
                    response.contentLength(), response.lastModified(),
                    checksum(response.metadata(), response.checksumSHA256())
            );
        } catch (AwsServiceException exception) {
            throw mapS3Exception(exception, key);
        }
    }

    private PatchObject fromListObject(S3Object object) {
        var fields = PatchKey.parse(object.key(), properties.prefix());
        return new PatchObject(
                fields.product(), fields.version(), fields.fileName(), object.key(),
                object.size(), object.lastModified(), null
        );
    }

    private void validateKey(String key) {
        if (key == null || !key.startsWith(properties.prefix())) {
            throw new IllegalArgumentException("key must be inside the configured patch prefix");
        }
        PatchKey.parse(key, properties.prefix());
    }

    private RuntimeException mapS3Exception(AwsServiceException exception, String key) {
        return switch (exception.statusCode()) {
            case 403 -> new PatchAccessDeniedException();
            case 404 -> new PatchNotFoundException(key);
            default -> exception;
        };
    }

    private String checksum(Map<String, String> metadata, String s3Checksum) {
        if (metadata != null && metadata.containsKey("sha256")) {
            return metadata.get("sha256");
        }
        return s3Checksum;
    }

    private record PatchKey(String product, String version, String fileName) {
        private static PatchKey parse(String key, String prefix) {
            String suffix = key.substring(prefix.length());
            String[] parts = suffix.split("/", -1);
            if (parts.length != 3 || parts[0].isBlank() || parts[1].isBlank() || parts[2].isBlank()) {
                throw new IllegalArgumentException("key must match patches/<product>/<version>/<filename>");
            }
            return new PatchKey(parts[0], parts[1], parts[2]);
        }
    }
}
