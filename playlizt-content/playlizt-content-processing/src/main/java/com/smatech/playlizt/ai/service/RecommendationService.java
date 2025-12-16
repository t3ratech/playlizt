/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/12/11 00:47
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import zw.co.t3ratech.playlizt.ai.client.ContentClient;
import zw.co.t3ratech.playlizt.ai.client.PlaybackClient;
import zw.co.t3ratech.playlizt.ai.dto.ContentResponse;
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
        // 1. Get Viewing History (defensive against downstream failures)
        JsonNode historyPage;
        try {
            historyPage = playbackClient.getViewingHistory(userId);
        } catch (Exception e) {
            log.error("Failed to fetch viewing history for user {}. Returning empty recommendations.", userId, e);
            return Collections.emptyList();
        }

        Set<Long> watchedContentIds = new HashSet<>();

        if (historyPage != null && historyPage.has("content")) {
            historyPage.get("content").forEach(node -> {
                if (node.has("contentId")) {
                    watchedContentIds.add(node.get("contentId").asLong());
                }
            });
        }

        int uniqueWatched = watchedContentIds.size();
        log.info("RecommendationService: userId={}, uniqueWatched={}", userId, uniqueWatched);

        // Requirement: Recommendations only display after the user has watched
        // at least 2 distinct pieces of content.
        if (uniqueWatched < 2) {
            return Collections.emptyList();
        }

        // 2. Get Categories (defensive)
        List<String> categories;
        try {
            categories = contentClient.getCategories();
        } catch (Exception e) {
            log.error("Failed to fetch categories for recommendations. Returning empty list.", e);
            return Collections.emptyList();
        }

        String targetCategory = "";
        if (categories != null && !categories.isEmpty()) {
            // Pick the first available category
            targetCategory = categories.get(0);
        }
        
        // 3. Search Content (defensive)
        JsonNode contentPage;
        try {
            contentPage = contentClient.searchContent("", targetCategory, 20);
        } catch (Exception e) {
            log.error("Failed to search content for recommendations. Returning empty list.", e);
            return Collections.emptyList();
        }

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
                log.error("Error parsing content response for recommendations. Returning empty list.", e);
                return Collections.emptyList();
            }
        }
        
        return recommendations;
    }
}
