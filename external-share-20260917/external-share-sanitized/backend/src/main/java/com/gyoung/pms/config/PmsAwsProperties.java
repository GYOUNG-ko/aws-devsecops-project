package com.gyoung.pms.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "pms.aws")
public record PmsAwsProperties(String region, String endpoint) {

    public PmsAwsProperties {
        if (region == null || region.isBlank()) {
            region = "ap-northeast-2";
        }
    }
}
