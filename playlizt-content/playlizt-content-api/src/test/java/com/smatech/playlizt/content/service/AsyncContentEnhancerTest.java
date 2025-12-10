package com.smatech.playlizt.content.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.smatech.playlizt.content.entity.Content;
import com.smatech.playlizt.content.repository.ContentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AsyncContentEnhancerTest {

    @Mock
    private GeminiAiService geminiAiService;

    @Mock
    private ContentRepository contentRepository;

    @InjectMocks
    private AsyncContentEnhancer asyncContentEnhancer;

    private Content content;
    private ObjectMapper mapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        content = Content.builder()
                .id(1L)
                .title("Test")
                .description("Desc")
                .tags(List.of("old"))
                .build();
    }

    @Test
    void enhanceContent_shouldUpdateMetadata() throws Exception {
        // Mock Gemini Response
        when(geminiAiService.enhanceMetadata(any(), any(), any())).thenReturn("raw json");
        
        ObjectNode json = mapper.createObjectNode();
        json.put("improvedDescription", "Better Desc");
        json.put("predictedCategory", "TECH");
        json.putArray("suggestedTags").add("AI").add("Java");
        json.put("relevanceScore", "0.95");
        json.put("contentRating", "PG-13");
        json.put("sentiment", "INSPIRING");
        
        when(geminiAiService.parseEnhancedMetadata("raw json")).thenReturn(json);
        
        asyncContentEnhancer.enhanceContent(content);
        
        verify(contentRepository).save(content);
        assertEquals("Better Desc", content.getAiGeneratedDescription());
        assertEquals("TECH", content.getAiPredictedCategory());
        assertTrue(content.getTags().contains("AI"));
        assertEquals(new BigDecimal("0.95"), content.getAiRelevanceScore());
        assertEquals("PG-13", content.getAiContentRating());
        assertEquals("INSPIRING", content.getAiSentiment());
    }
}
