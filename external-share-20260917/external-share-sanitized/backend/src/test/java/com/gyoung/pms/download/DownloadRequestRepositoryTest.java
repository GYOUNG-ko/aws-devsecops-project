package com.gyoung.pms.download;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.TestPropertySource;

@DataJpaTest
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:h2:mem:pms-repository;DB_CLOSE_DELAY=-1",
        "spring.jpa.hibernate.ddl-auto=validate",
        "spring.flyway.enabled=true",
        "spring.flyway.baseline-on-migrate=false"
})
class DownloadRequestRepositoryTest {

    @Autowired
    private DownloadRequestRepository repository;

    @Test
    void flywaySchemaSupportsPersistingAndQueryingRequests() {
        repository.save(new DownloadRequest(
                "customer-user", "customer-a", "patches/product/1.0/file.zip"));

        var requests = repository.findByRequestedByOrderByRequestedAtDesc("customer-user");

        assertThat(requests).hasSize(1);
        assertThat(requests.getFirst().getPatchKey())
                .isEqualTo("patches/product/1.0/file.zip");
    }
}
