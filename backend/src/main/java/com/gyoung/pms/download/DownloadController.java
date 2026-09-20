package com.gyoung.pms.download;
import java.security.Principal; import java.util.List;
import org.springframework.http.*; import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping(path="/api", produces=MediaType.APPLICATION_JSON_VALUE)
class DownloadController {
  private final DownloadWorkflowService service; DownloadController(DownloadWorkflowService service){this.service=service;}
  record DownloadRequestPayload(String customer, String patchKey) {}
  @PostMapping("/download-requests") @ResponseStatus(HttpStatus.CREATED) DownloadRequest request(@RequestBody DownloadRequestPayload body, Principal principal){ if(body.customer()==null||body.customer().isBlank()||body.patchKey()==null||!body.patchKey().startsWith("patches/")) throw new IllegalArgumentException("customer and patches/ key are required"); return service.request(principal.getName(),body.customer(),body.patchKey()); }
  @GetMapping("/download-requests/me") List<DownloadRequest> mine(Principal principal){return service.mine(principal.getName());}
  @GetMapping("/admin/download-requests") List<DownloadRequest> all(){return service.all();}
  @PostMapping("/admin/download-requests/{id}/approve") DownloadRequest approve(@PathVariable long id, Principal principal){return service.approve(id,principal.getName());}
  record DownloadUrl(String url, java.time.Instant expiresAt, DownloadRequest request) {}
  @PostMapping("/download-requests/{id}/issue") DownloadUrl issue(@PathVariable long id, Principal principal){var issued=service.issueUrl(id,principal.getName()); return new DownloadUrl(issued.url(),issued.expiresAt(),issued.request());}
  @PostMapping("/download-requests/{id}/used") DownloadRequest used(@PathVariable long id, Principal principal){return service.markUsed(id,principal.getName());}
}
