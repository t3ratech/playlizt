package com.smatech.playlizt.content.controller;

import com.smatech.playlizt.content.dto.ContentRequest;
import com.smatech.playlizt.content.dto.ContentResponse;
import com.smatech.playlizt.content.service.ContentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/content")
@RequiredArgsConstructor
@Tag(name = "Content", description = "Content management endpoints")
public class ContentController {

    private final ContentService contentService;

    @PostMapping
    @Operation(summary = "Add content", description = "Upload new content with optional AI enhancement")
    public ResponseEntity<ContentResponse> addContent(@Valid @RequestBody ContentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(contentService.addContent(request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get content", description = "Get content by ID")
    public ResponseEntity<ContentResponse> getContent(@PathVariable Long id) {
        return ResponseEntity.ok(contentService.getContent(id));
    }

    @GetMapping
    @Operation(summary = "List content", description = "Get all published content with pagination")
    public ResponseEntity<Page<ContentResponse>> getAllContent(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt,desc") String sort) {
        
        String[] sortParams = sort.split(",");
        Sort.Direction direction = sortParams.length > 1 && sortParams[1].equalsIgnoreCase("asc") 
                ? Sort.Direction.ASC 
                : Sort.Direction.DESC;
        
        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(direction, sortParams[0]));
        return ResponseEntity.ok(contentService.getAllContent(pageRequest));
    }

    @GetMapping("/search")
    @Operation(summary = "Search content", description = "Search content by query with optional filters")
    public ResponseEntity<Page<ContentResponse>> searchContent(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Integer minDuration,
            @RequestParam(required = false) Integer maxDuration,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt,desc") String sort) {
        
        String[] sortParams = sort.split(",");
        Sort.Direction direction = sortParams.length > 1 && sortParams[1].equalsIgnoreCase("asc") 
                ? Sort.Direction.ASC 
                : Sort.Direction.DESC;
        
        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(direction, sortParams[0]));
        return ResponseEntity.ok(contentService.searchContent(q, category, minDuration, maxDuration, pageRequest));
    }

    @GetMapping("/categories")
    @Operation(summary = "List categories", description = "Get all content categories")
    public ResponseEntity<List<String>> getCategories() {
        return ResponseEntity.ok(contentService.getAllCategories());
    }

    @PostMapping("/{id}/view")
    @Operation(summary = "Increment view count", description = "Increment the view count for a content item")
    public ResponseEntity<Void> incrementViewCount(@PathVariable Long id) {
        contentService.incrementViewCount(id);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update content", description = "Update existing content")
    public ResponseEntity<ContentResponse> updateContent(
            @PathVariable Long id,
            @Valid @RequestBody ContentRequest request) {
        return ResponseEntity.ok(contentService.updateContent(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete content", description = "Delete content by ID")
    public ResponseEntity<Void> deleteContent(@PathVariable Long id) {
        contentService.deleteContent(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/publish")
    @Operation(summary = "Publish content", description = "Make content publicly visible")
    public ResponseEntity<Void> publishContent(@PathVariable Long id) {
        contentService.publishContent(id);
        return ResponseEntity.ok().build();
    }
}
