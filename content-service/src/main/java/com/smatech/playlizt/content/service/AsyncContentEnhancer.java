package com.smatech.playlizt.content.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.smatech.playlizt.content.entity.Content;
import com.smatech.playlizt.content.repository.ContentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class AsyncContentEnhancer {

    private final GeminiAiService geminiAiService;
    private final ContentRepository contentRepository;

    @Async
    @Transactional
    public void enhanceContent(Content content) {
        log.info("Starting async AI enhancement for content id={}", content.getId());
        try {
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
            
            contentRepository.save(content);
            log.info("Completed async AI enhancement for content id={}", content.getId());
            
        } catch (Exception e) {
            log.error("Failed to enhance content with AI for id={}", content.getId(), e);
        }
    }
}
