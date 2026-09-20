package com.gyoung.pms.download;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
interface DownloadRequestRepository extends JpaRepository<DownloadRequest, Long> { List<DownloadRequest> findByRequestedByOrderByRequestedAtDesc(String requestedBy); }
