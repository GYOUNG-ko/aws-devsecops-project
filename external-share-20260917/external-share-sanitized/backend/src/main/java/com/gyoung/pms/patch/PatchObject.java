package com.gyoung.pms.patch;

import java.time.Instant;

public record PatchObject(
        String product,
        String version,
        String fileName,
        String key,
        long size,
        Instant lastModified,
        String checksum
) {
}
