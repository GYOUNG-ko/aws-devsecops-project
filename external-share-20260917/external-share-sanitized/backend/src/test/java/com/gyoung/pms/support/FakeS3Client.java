package com.gyoung.pms.support;

import java.lang.reflect.Proxy;
import java.util.function.Function;

import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectResponse;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Request;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Response;

public final class FakeS3Client {

    private FakeS3Client() {
    }

    public static S3Client create(
            Function<ListObjectsV2Request, ListObjectsV2Response> listHandler,
            Function<HeadObjectRequest, HeadObjectResponse> headHandler
    ) {
        return (S3Client) Proxy.newProxyInstance(
                FakeS3Client.class.getClassLoader(),
                new Class<?>[]{S3Client.class},
                (proxy, method, arguments) -> switch (method.getName()) {
                    case "listObjectsV2" -> listHandler.apply((ListObjectsV2Request) arguments[0]);
                    case "headObject" -> headHandler.apply((HeadObjectRequest) arguments[0]);
                    case "serviceName" -> "S3";
                    case "close" -> null;
                    case "toString" -> "FakeS3Client";
                    default -> throw new UnsupportedOperationException(method.getName());
                }
        );
    }
}
