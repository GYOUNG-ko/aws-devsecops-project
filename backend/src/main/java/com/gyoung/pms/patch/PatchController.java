package com.gyoung.pms.patch;

import java.util.List;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(path = "/api/patches", produces = MediaType.APPLICATION_JSON_VALUE)
public class PatchController {

    private final PatchService patchService;

    public PatchController(PatchService patchService) {
        this.patchService = patchService;
    }

    @GetMapping
    public List<PatchObject> listPatches() {
        return patchService.listPatches();
    }

    @GetMapping("/metadata")
    public PatchObject getMetadata(@RequestParam String key) {
        return patchService.getMetadata(key);
    }
}
