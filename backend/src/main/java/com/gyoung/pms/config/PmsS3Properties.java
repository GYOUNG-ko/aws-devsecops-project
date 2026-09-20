package com.gyoung.pms.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "pms.s3")
public record PmsS3Properties(String bucket, String prefix) {

    public PmsS3Properties {
        if (bucket == null || bucket.isBlank()) {
            throw new IllegalArgumentException("PMS_S3_BUCKET must be configured");
        }
        if (prefix == null || prefix.isBlank()) {
            prefix = "patches/";
        }
        if (!prefix.endsWith("/")) {
            prefix = prefix + "/";
        }
    }
}
