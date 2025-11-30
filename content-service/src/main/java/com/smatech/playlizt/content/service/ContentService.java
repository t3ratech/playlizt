package com.smatech.playlizt.content.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.smatech.playlizt.content.dto.ContentRequest;
import com.smatech.playlizt.content.dto.ContentResponse;
import com.smatech.playlizt.content.entity.Content;
import com.smatech.playlizt.content.repository.ContentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.data.jpa.domain.Specification;
import jakarta.persistence.criteria.Predicate;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ContentService {

    private final ContentRepository contentRepository;
    private final AsyncContentEnhancer asyncContentEnhancer;

    @Transactional
    public ContentResponse createContent(ContentRequest request) {
        log.info("Creating content: {}", request.getTitle());

        validateVideoUrl(request.getVideoUrl());

        Content content = Content.builder()
                .creatorId(request.getCreatorId())
                .title(request.getTitle())
                .description(request.getDescription())
                .category(request.getCategory())
                .tags(request.getTags())
                .thumbnailUrl(request.getThumbnailUrl())
                .videoUrl(request.getVideoUrl())
                .durationSeconds(request.getDurationSeconds())
                .isPublished(false)
                .viewCount(0L)
                .build();

        content = contentRepository.save(content);
        log.info("Content created successfully: id={}", content.getId());

        // Enhance with AI if requested (Async)
        if (Boolean.TRUE.equals(request.getEnhanceWithAi())) {
            asyncContentEnhancer.enhanceContent(content);
        }

        return toResponse(content);
    }

    @Transactional
    public ContentResponse updateContent(Long id, ContentRequest request) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Content not found"));

        if (request.getVideoUrl() != null && !request.getVideoUrl().equals(content.getVideoUrl())) {
             validateVideoUrl(request.getVideoUrl());
             content.setVideoUrl(request.getVideoUrl());
        }

        content.setTitle(request.getTitle());
        content.setDescription(request.getDescription());
        content.setCategory(request.getCategory());
        content.setTags(request.getTags());
        content.setThumbnailUrl(request.getThumbnailUrl());
        content.setDurationSeconds(request.getDurationSeconds());

        content = contentRepository.save(content);
        return toResponse(content);
    }
    
    private void validateVideoUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
             throw new IllegalArgumentException("Video URL is required");
        }
        // Regex for YouTube URLs (standard and shortened)
        if (!url.matches("^(https?://)?(www\\.)?(youtube\\.com/watch\\?v=|youtu\\.be/)[\\w-]{11}.*$")) {
            throw new IllegalArgumentException("Invalid Video URL. Only YouTube URLs are supported (e.g., https://www.youtube.com/watch?v=... or https://youtu.be/...)");
        }
    }

    public ContentResponse getContent(Long id) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Content not found"));
        return toResponse(content);
    }

    public Page<ContentResponse> getAllContent(Pageable pageable) {
        return contentRepository.findByIsPublishedTrue(pageable)
                .map(this::toResponse);
    }

    public Page<ContentResponse> searchContent(String query, String category, Integer minDuration, Integer maxDuration, Pageable pageable) {
        Specification<Content> spec = (root, queryObj, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            
            // Published only
            predicates.add(cb.isTrue(root.get("isPublished")));
            
            // Query (Title or Description)
            if (query != null && !query.trim().isEmpty()) {
                String likePattern = "%" + query.toLowerCase() + "%";
                predicates.add(cb.or(
                    cb.like(cb.lower(root.get("title")), likePattern),
                    cb.like(cb.lower(root.get("description")), likePattern)
                ));
            }
            
            // Category
            if (category != null && !category.trim().isEmpty()) {
                predicates.add(cb.equal(root.get("category"), category));
            }
            
            // Duration
            if (minDuration != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("durationSeconds"), minDuration));
            }
            if (maxDuration != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("durationSeconds"), maxDuration));
            }
            
            return cb.and(predicates.toArray(new Predicate[0]));
        };
        
        return contentRepository.findAll(spec, pageable)
                .map(this::toResponse);
    }

    public List<String> getAllCategories() {
        return contentRepository.findAllCategories();
    }

    @Transactional
    public void incrementViewCount(Long id) {
        contentRepository.incrementViewCount(id);
    }


    @Transactional
    public void deleteContent(Long id) {
        contentRepository.deleteById(id);
    }

    @Transactional
    public void publishContent(Long id) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Content not found"));
        content.setIsPublished(true);
        contentRepository.save(content);
    }

    private ContentResponse toResponse(Content content) {
        return ContentResponse.builder()
                .id(content.getId())
                .creatorId(content.getCreatorId())
                .title(content.getTitle())
                .description(content.getDescription())
                .category(content.getCategory())
                .tags(content.getTags())
                .thumbnailUrl(content.getThumbnailUrl())
                .videoUrl(content.getVideoUrl())
                .durationSeconds(content.getDurationSeconds())
                .aiGeneratedDescription(content.getAiGeneratedDescription())
                .aiPredictedCategory(content.getAiPredictedCategory())
                .aiRelevanceScore(content.getAiRelevanceScore())
                .createdAt(content.getCreatedAt())
                .updatedAt(content.getUpdatedAt())
                .isPublished(content.getIsPublished())
                .viewCount(content.getViewCount())
                .build();
    }
}
