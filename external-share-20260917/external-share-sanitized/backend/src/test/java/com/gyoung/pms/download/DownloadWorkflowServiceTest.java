package com.gyoung.pms.download;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import java.lang.reflect.Proxy;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;

import com.gyoung.pms.config.PmsS3Properties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;

class DownloadWorkflowServiceTest {

    private DownloadRequestRepository repository;
    private DownloadWorkflowService service;
    private AtomicReference<DownloadRequest> stored;

    @BeforeEach
    void setUp() {
        stored = new AtomicReference<>();
        repository = (DownloadRequestRepository) Proxy.newProxyInstance(
                DownloadRequestRepository.class.getClassLoader(),
                new Class<?>[]{DownloadRequestRepository.class},
                (proxy, method, arguments) -> switch (method.getName()) {
                    case "save" -> {
                        var request = (DownloadRequest) arguments[0];
                        stored.set(request);
                        yield request;
                    }
                    case "findById" -> Optional.ofNullable(stored.get());
                    case "findByRequestedByOrderByRequestedAtDesc" -> {
                        var request = stored.get();
                        yield request != null && request.getRequestedBy().equals(arguments[0])
                                ? List.of(request) : List.of();
                    }
                    case "findAll" -> stored.get() == null ? List.of() : List.of(stored.get());
                    case "toString" -> "DownloadRequestRepositoryStub";
                    default -> throw new UnsupportedOperationException(method.getName());
                });
        service = new DownloadWorkflowService(
                repository,
                null,
                new PmsS3Properties("private-pms-bucket", "patches/"));
    }

    @Test
    void createsAPendingRequestForTheAuthenticatedUser() {
        var request = service.request(
                "customer-user", "customer-a", "patches/product/1.0/file.zip");

        assertThat(request.getRequestedBy()).isEqualTo("customer-user");
        assertThat(request.getStatus()).isEqualTo(DownloadStatus.PENDING);
    }

    @Test
    void approvesAndIssuesOnlyToTheRequestOwner() {
        var request = new DownloadRequest(
                "customer-user", "customer-a", "patches/product/1.0/file.zip");
        repository.save(request);

        service.approve(1L, "admin-user");
        var issued = service.issue(1L, "customer-user");

        assertThat(issued.getStatus()).isEqualTo(DownloadStatus.URL_ISSUED);
        assertThat(issued.getApprovedBy()).isEqualTo("admin-user");
    }

    @Test
    void preventsAnotherUserFromIssuingTheUrl() {
        var request = new DownloadRequest(
                "customer-user", "customer-a", "patches/product/1.0/file.zip");
        request.approve("admin-user");
        repository.save(request);

        assertThatThrownBy(() -> service.issue(1L, "different-user"))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void returnsOnlyTheAuthenticatedUsersRequests() {
        var request = new DownloadRequest(
                "customer-user", "customer-a", "patches/product/1.0/file.zip");
        repository.save(request);

        assertThat(service.mine("customer-user")).containsExactly(request);
    }
}
