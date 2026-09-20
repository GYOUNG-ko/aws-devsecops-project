package com.gyoung.pms.patch;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import software.amazon.awssdk.awscore.exception.AwsServiceException;
import software.amazon.awssdk.core.exception.SdkClientException;

@RestControllerAdvice
public class S3ExceptionHandler {

    @ExceptionHandler(PatchNotFoundException.class)
    ResponseEntity<Map<String, String>> notFound(PatchNotFoundException exception) {
        return error(HttpStatus.NOT_FOUND, "PATCH_NOT_FOUND");
    }

    @ExceptionHandler(PatchAccessDeniedException.class)
    ResponseEntity<Map<String, String>> accessDenied(PatchAccessDeniedException exception) {
        return error(HttpStatus.FORBIDDEN, "PATCH_ACCESS_DENIED");
    }

    @ExceptionHandler(IllegalArgumentException.class)
    ResponseEntity<Map<String, String>> badRequest(IllegalArgumentException exception) {
        return error(HttpStatus.BAD_REQUEST, "INVALID_PATCH_KEY");
    }

    @ExceptionHandler(AwsServiceException.class)
    ResponseEntity<Map<String, String>> s3Failure(AwsServiceException exception) {
        return error(HttpStatus.BAD_GATEWAY, "PATCH_STORAGE_UNAVAILABLE");
    }

    @ExceptionHandler(SdkClientException.class)
    ResponseEntity<Map<String, String>> s3ClientFailure(SdkClientException exception) {
        return error(HttpStatus.BAD_GATEWAY, "PATCH_STORAGE_UNAVAILABLE");
    }

    private ResponseEntity<Map<String, String>> error(HttpStatus status, String code) {
        return ResponseEntity.status(status).body(Map.of("code", code));
    }
}
