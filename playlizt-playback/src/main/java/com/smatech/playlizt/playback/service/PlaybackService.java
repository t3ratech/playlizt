package com.smatech.playlizt.playback.service;

import com.smatech.playlizt.playback.dto.PlaybackRequest;
import com.smatech.playlizt.playback.dto.PlaybackResponse;
import com.smatech.playlizt.playback.entity.ViewingHistory;
import com.smatech.playlizt.playback.repository.ViewingHistoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class PlaybackService {

    private final ViewingHistoryRepository viewingHistoryRepository;

    @Transactional
    public PlaybackResponse startOrUpdatePlayback(PlaybackRequest request) {
        log.info("Processing playback for user {} on content {}", request.getUserId(), request.getContentId());

        ViewingHistory history = viewingHistoryRepository
                .findByUserIdAndContentId(request.getUserId(), request.getContentId())
                .orElseGet(() -> ViewingHistory.builder()
                        .userId(request.getUserId())
                        .contentId(request.getContentId())
                        .watchTimeSeconds(0)
                        .lastPositionSeconds(0)
                        .completed(false)
                        .build());

        // Update position
        if (request.getPositionSeconds() != null) {
            int positionDiff = request.getPositionSeconds() - history.getLastPositionSeconds();
            if (positionDiff > 0) {
                history.setWatchTimeSeconds(history.getWatchTimeSeconds() + positionDiff);
            }
            history.setLastPositionSeconds(request.getPositionSeconds());
        }

        // Mark as completed if requested
        if (Boolean.TRUE.equals(request.getCompleted())) {
            history.setCompleted(true);
        }

        history = viewingHistoryRepository.save(history);
        log.info("Playback updated: watchTime={}s, position={}s", 
                history.getWatchTimeSeconds(), history.getLastPositionSeconds());

        return toResponse(history);
    }

    public PlaybackResponse getPlaybackStatus(Long userId, Long contentId) {
        ViewingHistory history = viewingHistoryRepository
                .findByUserIdAndContentId(userId, contentId)
                .orElseThrow(() -> new IllegalArgumentException("No playback history found"));
        return toResponse(history);
    }

    public Page<PlaybackResponse> getViewingHistory(Long userId, Pageable pageable) {
        return viewingHistoryRepository.findByUserId(userId, pageable)
                .map(this::toResponse);
    }

    public Page<PlaybackResponse> getContinueWatching(Long userId, Pageable pageable) {
        return viewingHistoryRepository.findContinueWatching(userId, pageable)
                .map(this::toResponse);
    }

    public Long getUniqueViewers(Long contentId) {
        return viewingHistoryRepository.countUniqueViewersByContentId(contentId);
    }

    public Long getTotalWatchTime(Long contentId) {
        Long total = viewingHistoryRepository.sumWatchTimeByContentId(contentId);
        return total != null ? total : 0L;
    }
    
    public Map<String, Long> getPlatformAnalytics() {
        Long totalSessions = viewingHistoryRepository.count();
        Long totalWatchTime = viewingHistoryRepository.sumTotalWatchTime();
        return Map.of(
            "totalSessions", totalSessions,
            "totalWatchTimeSeconds", totalWatchTime != null ? totalWatchTime : 0L
        );
    }

    private PlaybackResponse toResponse(ViewingHistory history) {
        return PlaybackResponse.builder()
                .id(history.getId())
                .userId(history.getUserId())
                .contentId(history.getContentId())
                .watchTimeSeconds(history.getWatchTimeSeconds())
                .lastPositionSeconds(history.getLastPositionSeconds())
                .completed(history.getCompleted())
                .createdAt(history.getCreatedAt())
                .updatedAt(history.getUpdatedAt())
                .build();
    }
}
