package com.smatech.playlizt.content.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "content", indexes = {
    @Index(name = "idx_content_creator", columnList = "creator_id"),
    @Index(name = "idx_content_category", columnList = "category"),
    @Index(name = "idx_content_published", columnList = "is_published")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Content {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, name = "creator_id")
    private Long creatorId;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, length = 100)
    private String category;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "content_tags", joinColumns = @JoinColumn(name = "content_id"))
    @Column(name = "tag")
    @Builder.Default
    private List<String> tags = new ArrayList<>();

    @Column(name = "thumbnail_url", length = 500)
    private String thumbnailUrl;

    @Column(name = "video_url", length = 500)
    private String videoUrl;

    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @Column(name = "ai_generated_description", columnDefinition = "TEXT")
    private String aiGeneratedDescription;

    @Column(name = "ai_predicted_category", length = 100)
    private String aiPredictedCategory;

    @Column(name = "ai_relevance_score", precision = 3, scale = 2)
    private BigDecimal aiRelevanceScore;

    @Column(name = "ai_content_rating", length = 20)
    private String aiContentRating;

    @Column(name = "ai_sentiment", length = 20)
    private String aiSentiment;

    @CreationTimestamp
    @Column(nullable = false, updatable = false, name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false, name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(nullable = false, name = "is_published")
    private Boolean isPublished = false;

    @Column(name = "view_count")
    private Long viewCount = 0L;
}
