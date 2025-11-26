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

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ContentService {

    private final ContentRepository contentRepository;
    private final GeminiAiService geminiAiService;

    @Transactional
    public ContentResponse createContent(ContentRequest request) {
        log.info("Creating content: {}", request.getTitle());

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

        // Enhance with AI if requested
        if (Boolean.TRUE.equals(request.getEnhanceWithAi())) {
            try {
                enhanceContentWithAi(content);
            } catch (Exception e) {
                log.error("Failed to enhance content with AI, proceeding without enhancement", e);
            }
        }

        content = contentRepository.save(content);
        log.info("Content created successfully: id={}", content.getId());

        return toResponse(content);
    }

    private void enhanceContentWithAi(Content content) {
        String aiResponse = geminiAiService.enhanceMetadata(
                content.getTitle(),
                content.getDescription(),
                content.getTags()
        );

        JsonNode metadata = geminiAiService.parseEnhancedMetadata(aiResponse);

        if (metadata.has("improvedDescription")) {
            content.setAiGeneratedDescription(metadata.get("improvedDescription").asText());
        }

        if (metadata.has("predictedCategory")) {
            content.setAiPredictedCategory(metadata.get("predictedCategory").asText());
        }

        if (metadata.has("suggestedTags") && metadata.get("suggestedTags").isArray()) {
            List<String> suggestedTags = new ArrayList<>();
            metadata.get("suggestedTags").forEach(tag -> suggestedTags.add(tag.asText()));
            content.setTags(suggestedTags.toArray(new String[0]));
        }

        if (metadata.has("relevanceScore")) {
            content.setAiRelevanceScore(new BigDecimal(metadata.get("relevanceScore").asText()));
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

    public Page<ContentResponse> getContentByCategory(String category, Pageable pageable) {
        return contentRepository.findByCategory(category, pageable)
                .map(this::toResponse);
    }

    public Page<ContentResponse> searchContent(String query, Pageable pageable) {
        return contentRepository.searchContent(query, pageable)
                .map(this::toResponse);
    }

    public List<String> getAllCategories() {
        return contentRepository.findAllCategories();
    }

    @Transactional
    public ContentResponse updateContent(Long id, ContentRequest request) {
        Content content = contentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Content not found"));

        content.setTitle(request.getTitle());
        content.setDescription(request.getDescription());
        content.setCategory(request.getCategory());
        content.setTags(request.getTags());
        content.setThumbnailUrl(request.getThumbnailUrl());
        content.setVideoUrl(request.getVideoUrl());
        content.setDurationSeconds(request.getDurationSeconds());

        content = contentRepository.save(content);
        return toResponse(content);
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
