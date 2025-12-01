package com.smatech.playlizt.ai.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class ContentResponse {
    private Long id;
    private Long creatorId;
    private String title;
    private String description;
    private String category;
    private String[] tags;
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
