/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/27 20:51
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.content.controller;

import zw.co.t3ratech.playlizt.content.service.LocalFileStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.MalformedURLException;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/content")
@RequiredArgsConstructor
@Tag(name = "Uploads", description = "File upload and retrieval endpoints")
public class UploadController {

    private final LocalFileStorageService fileStorageService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload file", description = "Upload video or thumbnail")
    public ResponseEntity<Map<String, String>> uploadFile(@RequestParam("file") MultipartFile file) {
        String fileName = fileStorageService.storeFile(file);
        
        // Construct URL. In production, this would be an S3 URL.
        // Here we return a URL that points back to this service via Gateway.
        // Gateway routes /api/v1/content/** to content-service.
        // So /api/v1/content/files/{fileName} works.
        
        String fileUrl = "/api/v1/content/files/" + fileName;
        
        Map<String, String> response = new HashMap<>();
        response.put("url", fileUrl);
        response.put("fileName", fileName);
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/files/{fileName:.+}")
    @Operation(summary = "Download file", description = "Retrieve uploaded file")
    public ResponseEntity<Resource> downloadFile(@PathVariable String fileName) {
        Path filePath = fileStorageService.loadFile(fileName);
        try {
            Resource resource = new UrlResource(filePath.toUri());
            if(resource.exists() || resource.isReadable()) {
                // Detect content type
                String contentType = "application/octet-stream";
                // Simple detection could be added based on extension
                
                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(contentType))
                        .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"")
                        .body(resource);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (MalformedURLException e) {
            return ResponseEntity.internalServerError().build();
        }
    }
}
