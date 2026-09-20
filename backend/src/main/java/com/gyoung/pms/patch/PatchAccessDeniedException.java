package com.gyoung.pms.patch;

public class PatchAccessDeniedException extends RuntimeException {

    public PatchAccessDeniedException() {
        super("Access to the patch object was denied");
    }
}
