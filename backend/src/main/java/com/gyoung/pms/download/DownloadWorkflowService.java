package com.gyoung.pms.download;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.gyoung.pms.config.PmsS3Properties;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import java.time.Duration;

@Service
class DownloadWorkflowService {
    private final DownloadRequestRepository repository; private final S3Presigner presigner; private final PmsS3Properties s3;
    DownloadWorkflowService(DownloadRequestRepository repository, S3Presigner presigner, PmsS3Properties s3) { this.repository=repository; this.presigner=presigner; this.s3=s3; }
    @Transactional DownloadRequest request(String user, String customer, String key) { return repository.save(new DownloadRequest(user, customer, key)); }
    List<DownloadRequest> mine(String user) { return repository.findByRequestedByOrderByRequestedAtDesc(user); }
    List<DownloadRequest> all() { return repository.findAll(); }
    @Transactional DownloadRequest approve(long id, String admin) { DownloadRequest request=get(id); if(request.getStatus()!=DownloadStatus.PENDING) throw new IllegalStateException("only PENDING requests can be approved"); request.approve(admin); return request; }
    @Transactional DownloadRequest issue(long id, String user) { DownloadRequest request=get(id); if(!request.getRequestedBy().equals(user)) throw new org.springframework.security.access.AccessDeniedException("not request owner"); if(request.getStatus()!=DownloadStatus.APPROVED) throw new IllegalStateException("only APPROVED requests can receive a URL"); request.issue(); return request; }
    @Transactional IssuedUrl issueUrl(long id, String user) { DownloadRequest request=issue(id,user); var signed=presigner.presignGetObject(GetObjectPresignRequest.builder().signatureDuration(Duration.ofMinutes(5)).getObjectRequest(GetObjectRequest.builder().bucket(s3.bucket()).key(request.getPatchKey()).build()).build()); return new IssuedUrl(request, signed.url().toString(), signed.expiration()); }
    @Transactional DownloadRequest markUsed(long id, String user) { DownloadRequest request=get(id); if(!request.getRequestedBy().equals(user)) throw new org.springframework.security.access.AccessDeniedException("not request owner"); if(request.getStatus()!=DownloadStatus.URL_ISSUED) throw new IllegalStateException("download is already consumed or not issued"); request.used(); return request; }
    private DownloadRequest get(long id) { return repository.findById(id).orElseThrow(() -> new java.util.NoSuchElementException("request not found")); }
    record IssuedUrl(DownloadRequest request, String url, java.time.Instant expiresAt) { }
}
