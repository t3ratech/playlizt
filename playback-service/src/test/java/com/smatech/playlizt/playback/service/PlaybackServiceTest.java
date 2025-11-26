package com.smatech.playlizt.playback.service;

import com.smatech.playlizt.playback.dto.PlaybackRequest;
import com.smatech.playlizt.playback.dto.PlaybackResponse;
import com.smatech.playlizt.playback.entity.ViewingHistory;
import com.smatech.playlizt.playback.repository.ViewingHistoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.Arrays;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PlaybackServiceTest {

    @Mock
    private ViewingHistoryRepository viewingHistoryRepository;

    @InjectMocks
    private PlaybackService playbackService;

    private ViewingHistory testHistory;
    private PlaybackRequest testRequest;

    @BeforeEach
    void setUp() {
        testHistory = ViewingHistory.builder()
                .id(1L)
                .userId(100L)
                .contentId(200L)
                .watchTimeSeconds(60)
                .lastPositionSeconds(30)
                .completed(false)
                .build();

        testRequest = PlaybackRequest.builder()
                .userId(100L)
                .contentId(200L)
                .positionSeconds(30)
                .build();
    }

    @Test
    void shouldStartOrUpdatePlayback() {
        when(viewingHistoryRepository.findByUserIdAndContentId(100L, 200L))
                .thenReturn(Optional.of(testHistory));
        when(viewingHistoryRepository.save(any(ViewingHistory.class))).thenReturn(testHistory);

        PlaybackResponse response = playbackService.startOrUpdatePlayback(testRequest);

        assertNotNull(response);
        verify(viewingHistoryRepository, times(1)).save(any(ViewingHistory.class));
    }

    @Test
    void shouldCreateNewPlaybackHistory() {
        when(viewingHistoryRepository.findByUserIdAndContentId(100L, 200L))
                .thenReturn(Optional.empty());
        when(viewingHistoryRepository.save(any(ViewingHistory.class))).thenReturn(testHistory);

        PlaybackResponse response = playbackService.startOrUpdatePlayback(testRequest);

        assertNotNull(response);
        verify(viewingHistoryRepository, times(1)).save(any(ViewingHistory.class));
    }

    @Test
    void shouldGetPlaybackStatus() {
        when(viewingHistoryRepository.findByUserIdAndContentId(100L, 200L))
                .thenReturn(Optional.of(testHistory));

        PlaybackResponse response = playbackService.getPlaybackStatus(100L, 200L);

        assertNotNull(response);
        assertEquals(100L, response.getUserId());
    }

    @Test
    void shouldGetViewingHistory() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<ViewingHistory> historyPage = new PageImpl<>(Arrays.asList(testHistory));
        when(viewingHistoryRepository.findByUserId(100L, pageable)).thenReturn(historyPage);

        Page<PlaybackResponse> result = playbackService.getViewingHistory(100L, pageable);

        assertNotNull(result);
        assertEquals(1, result.getTotalElements());
    }

    @Test
    void shouldGetContinueWatching() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<ViewingHistory> historyPage = new PageImpl<>(Arrays.asList(testHistory));
        when(viewingHistoryRepository.findContinueWatching(100L, pageable)).thenReturn(historyPage);

        Page<PlaybackResponse> result = playbackService.getContinueWatching(100L, pageable);

        assertNotNull(result);
        assertEquals(1, result.getTotalElements());
    }

    @Test
    void shouldGetUniqueViewers() {
        when(viewingHistoryRepository.countUniqueViewersByContentId(200L)).thenReturn(5L);

        Long viewers = playbackService.getUniqueViewers(200L);

        assertEquals(5L, viewers);
    }

    @Test
    void shouldGetTotalWatchTime() {
        when(viewingHistoryRepository.sumWatchTimeByContentId(200L)).thenReturn(1200L);

        Long watchTime = playbackService.getTotalWatchTime(200L);

        assertEquals(1200L, watchTime);
    }
}
