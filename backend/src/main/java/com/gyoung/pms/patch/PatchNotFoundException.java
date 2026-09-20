package com.gyoung.pms.patch;

public class PatchNotFoundException extends RuntimeException {

    public PatchNotFoundException(String key) {
        super("Patch object was not found: " + key);
    }
}
