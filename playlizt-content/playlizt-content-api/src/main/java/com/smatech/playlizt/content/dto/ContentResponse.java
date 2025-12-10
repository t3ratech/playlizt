package com.smatech.playlizt.content.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContentResponse {
    private Long id;
    private Long creatorId;
    private String title;
    private String description;
    private String category;
    private List<String> tags;
    private String thumbnailUrl;
    private String videoUrl;
    private Integer durationSeconds;
    private String aiGeneratedDescription;
    private String aiPredictedCategory;
    private BigDecimal aiRelevanceScore;
    private String aiContentRating;
    private String aiSentiment;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Boolean isPublished;
    private Long viewCount;
}
