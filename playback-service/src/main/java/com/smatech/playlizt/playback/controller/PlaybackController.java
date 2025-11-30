package com.smatech.playlizt.playback.controller;

import com.smatech.playlizt.playback.dto.PlaybackRequest;
import com.smatech.playlizt.playback.dto.PlaybackResponse;
import com.smatech.playlizt.playback.service.PlaybackService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/playback")
@RequiredArgsConstructor
@Tag(name = "Playback", description = "Video playback and viewing history endpoints")
public class PlaybackController {

    private final PlaybackService playbackService;

    @PostMapping("/track")
    @Operation(summary = "Track playback", description = "Start or update playback session")
    public ResponseEntity<PlaybackResponse> trackPlayback(@Valid @RequestBody PlaybackRequest request) {
        return ResponseEntity.ok(playbackService.startOrUpdatePlayback(request));
    }

    @GetMapping("/status")
    @Operation(summary = "Get playback status", description = "Get current playback position for user and content")
    public ResponseEntity<PlaybackResponse> getPlaybackStatus(
            @RequestParam Long userId,
            @RequestParam Long contentId) {
        return ResponseEntity.ok(playbackService.getPlaybackStatus(userId, contentId));
    }

    @GetMapping("/history")
    @Operation(summary = "Get viewing history", description = "Get all viewing history for a user")
    public ResponseEntity<Page<PlaybackResponse>> getViewingHistory(
            @RequestParam Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        PageRequest pageRequest = PageRequest.of(page, size);
        return ResponseEntity.ok(playbackService.getViewingHistory(userId, pageRequest));
    }

    @GetMapping("/continue")
    @Operation(summary = "Continue watching", description = "Get list of partially watched content")
    public ResponseEntity<Page<PlaybackResponse>> getContinueWatching(
            @RequestParam Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        try {
            PageRequest pageRequest = PageRequest.of(page, size);
            return ResponseEntity.ok(playbackService.getContinueWatching(userId, pageRequest));
        } catch (Exception e) {
            // Log error but return empty page to prevent UI crash
            System.err.println("Error fetching continue watching list: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.ok(Page.empty());
        }
    }

    @GetMapping("/analytics/content/{contentId}")
    @Operation(summary = "Content analytics", description = "Get viewing analytics for specific content")
    public ResponseEntity<Map<String, Object>> getContentAnalytics(@PathVariable Long contentId) {
        Long uniqueViewers = playbackService.getUniqueViewers(contentId);
        Long totalWatchTime = playbackService.getTotalWatchTime(contentId);
        
        return ResponseEntity.ok(Map.of(
                "contentId", contentId,
                "uniqueViewers", uniqueViewers,
                "totalWatchTimeSeconds", totalWatchTime
        ));
    }
    
    @GetMapping("/analytics/platform")
    @Operation(summary = "Platform analytics", description = "Get global platform analytics (Admin only)")
    public ResponseEntity<Map<String, Long>> getPlatformAnalytics() {
        return ResponseEntity.ok(playbackService.getPlatformAnalytics());
    }
}
