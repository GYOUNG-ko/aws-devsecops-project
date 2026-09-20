package com.gyoung.pms.download;

import java.time.Instant;
import jakarta.persistence.*;

@Entity
@Table(name = "download_requests")
public class DownloadRequest {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(nullable = false) private String requestedBy;
    @Column(nullable = false) private String customer;
    @Column(nullable = false, length = 1024) private String patchKey;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 32) private DownloadStatus status = DownloadStatus.PENDING;
    @Column(nullable = false) private Instant requestedAt = Instant.now();
    private Instant approvedAt; private String approvedBy; private Instant downloadedAt;
    protected DownloadRequest() { }
    DownloadRequest(String user, String customer, String key) { this.requestedBy=user; this.customer=customer; this.patchKey=key; }
    public Long getId(){return id;} public String getRequestedBy(){return requestedBy;} public String getCustomer(){return customer;} public String getPatchKey(){return patchKey;} public DownloadStatus getStatus(){return status;} public Instant getRequestedAt(){return requestedAt;} public Instant getApprovedAt(){return approvedAt;} public String getApprovedBy(){return approvedBy;} public Instant getDownloadedAt(){return downloadedAt;}
    void approve(String admin){ status=DownloadStatus.APPROVED; approvedAt=Instant.now(); approvedBy=admin; }
    void issue(){ status=DownloadStatus.URL_ISSUED; }
    void used(){ status=DownloadStatus.USED; downloadedAt=Instant.now(); }
}
