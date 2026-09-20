package com.gyoung.pms;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.jupiter.api.Test;

class PmsWebContractTest {

    @Test
    void webUiCallsThePatchAndMetadataApiAndProvidesRequiredStates() throws Exception {
        String html = Files.readString(Path.of("../app/index.html"));

        assertThat(html)
                .contains("PMS Patch Portal")
                .contains("fetch('/api/patches')")
                .contains("/api/patches/metadata?key=")
                .contains("패치 목록을 불러오는 중입니다.")
                .contains("등록된 패치가 없습니다.")
                .contains("패치 목록을 불러오지 못했습니다.")
                .contains("다운로드 준비 중");
    }
}
