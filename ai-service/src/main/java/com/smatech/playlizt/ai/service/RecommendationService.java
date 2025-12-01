package com.smatech.playlizt.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smatech.playlizt.ai.client.ContentClient;
import com.smatech.playlizt.ai.client.PlaybackClient;
import com.smatech.playlizt.ai.dto.ContentResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class RecommendationService {

    private final ContentClient contentClient;
    private final PlaybackClient playbackClient;
    private final ObjectMapper objectMapper;

    public List<ContentResponse> getRecommendations(Long userId) {
        // 1. Get Viewing History
        JsonNode historyPage = playbackClient.getViewingHistory(userId);
        Set<Long> watchedContentIds = new HashSet<>();
        long totalViews = 0;
        
        if (historyPage != null) {
            if (historyPage.has("totalElements")) {
                totalViews = historyPage.get("totalElements").asLong();
            }
            
            if (historyPage.has("content")) {
                historyPage.get("content").forEach(node -> {
                    if (node.has("contentId")) {
                        watchedContentIds.add(node.get("contentId").asLong());
                    }
                });
            }
        }

        // Requirement: Recommendations only display after playing 2 videos (Total views > 2)
        // "exceeds 2 views in total"
        if (totalViews <= 2) {
            return new ArrayList<>();
        }

        // 2. Get Categories
        List<String> categories = contentClient.getCategories();
        String targetCategory = "";
        if (categories != null && !categories.isEmpty()) {
            // Pick a random category or the first one
            targetCategory = categories.get(0);
        }
        
        // 3. Search Content
        JsonNode contentPage = contentClient.searchContent("", targetCategory, 20);
        
        List<ContentResponse> recommendations = new ArrayList<>();
        if (contentPage != null && contentPage.has("content")) {
            try {
                String json = contentPage.get("content").toString();
                ContentResponse[] contents = objectMapper.readValue(json, ContentResponse[].class);
                
                for (ContentResponse c : contents) {
                    if (!watchedContentIds.contains(c.getId())) {
                        recommendations.add(c);
                    }
                }
            } catch (Exception e) {
                log.error("Error parsing content response", e);
            }
        }
        
        return recommendations;
    }
}
