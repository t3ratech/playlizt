package com.smatech.playlizt.playback.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlaybackRequest {

    @NotNull(message = "User ID is required")
    private Long userId;

    @NotNull(message = "Content ID is required")
    private Long contentId;

    @Min(value = 0, message = "Position must be non-negative")
    private Integer positionSeconds;

    private Boolean completed = false;
}
