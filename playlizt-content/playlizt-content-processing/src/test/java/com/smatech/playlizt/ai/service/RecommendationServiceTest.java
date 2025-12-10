package com.smatech.playlizt.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smatech.playlizt.ai.client.ContentClient;
import com.smatech.playlizt.ai.client.PlaybackClient;
import com.smatech.playlizt.ai.dto.ContentResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RecommendationServiceTest {

    @Mock
    private ContentClient contentClient;

    @Mock
    private PlaybackClient playbackClient;

    @Mock
    private ObjectMapper objectMapper;

    @InjectMocks
    private RecommendationService recommendationService;

    @Test
    void getRecommendations_shouldReturnContent() throws Exception {
        // Mock Viewing History with 2 viewed items and totalElements > 2 to satisfy threshold
        ObjectMapper realMapper = new ObjectMapper();
        JsonNode historyNode = realMapper.readTree("{\"totalElements\": 3, \"content\": [{\"contentId\": 99}, {\"contentId\": 98}]}");
        when(playbackClient.getViewingHistory(1L)).thenReturn(historyNode);
        
        // Mock Categories
        when(contentClient.getCategories()).thenReturn(List.of("ENTERTAINMENT"));
        
        // Mock Content Search
        JsonNode contentPage = mock(JsonNode.class);
        when(contentClient.searchContent(eq(""), eq("ENTERTAINMENT"), eq(20))).thenReturn(contentPage);
        when(contentPage.has("content")).thenReturn(true);
        
        // Mock Content Response Parsing
        JsonNode contentList = mock(JsonNode.class);
        when(contentPage.get("content")).thenReturn(contentList);
        when(contentList.toString()).thenReturn("[]");
        
        ContentResponse[] responses = new ContentResponse[1];
        ContentResponse c = new ContentResponse();
        c.setId(10L);
        c.setTitle("Recommended");
        responses[0] = c;
        
        when(objectMapper.readValue("[]", ContentResponse[].class)).thenReturn(responses);
        
        List<ContentResponse> result = recommendationService.getRecommendations(1L);
        
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(10L, result.get(0).getId());
    }
}
