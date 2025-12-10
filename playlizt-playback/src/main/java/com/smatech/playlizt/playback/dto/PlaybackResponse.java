package com.smatech.playlizt.playback.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlaybackResponse {
    private Long id;
    private Long userId;
    private Long contentId;
    private Integer watchTimeSeconds;
    private Integer lastPositionSeconds;
    private Boolean completed;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
