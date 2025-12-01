package com.smatech.playlizt.content.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.genai.Client;
import com.google.genai.types.GenerateContentResponse;
import com.smatech.playlizt.content.config.GeminiConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class GeminiAiService {

    private final GeminiConfig geminiConfig;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public String enhanceMetadata(String title, String description, List<String> tags) {
        Client client = Client.builder()
                .apiKey(geminiConfig.getKey())
                .build();

        String prompt = buildMetadataPrompt(title, description, tags);
        
        List<String> modelsToTry = getModelsToTry();
        
        for (String model : modelsToTry) {
            try {
                log.debug("Attempting Gemini call with model: {}", model);
                GenerateContentResponse response = client.models.generateContent(
                        model,
                        prompt,
                        null
                );
                
                String result = response.text();
                log.info("Successfully enhanced metadata using model: {}", model);
                return result;
            } catch (Exception e) {
                log.warn("Gemini call failed for model {}: {}", model, e.getMessage());
            }
        }
        
        throw new IllegalStateException("Failed to enhance metadata with all available models");
    }

    private String buildMetadataPrompt(String title, String description, List<String> tags) {
        String tagsStr = tags != null ? String.join(", ", tags) : "";
        
        return String.format("""
            Analyze this video content and provide enhanced metadata in JSON format.
            
            Title: %s
            Description: %s
            Tags: %s
            
            Generate a JSON response with:
            1. "improvedDescription": A compelling 200-500 character description optimized for discovery
            2. "suggestedTags": Array of 5-10 relevant tags
            3. "predictedCategory": One of [EDUCATION, ENTERTAINMENT, TECHNOLOGY, MUSIC, SPORTS, NEWS, GAMING, LIFESTYLE, COOKING, TRAVEL]
            4. "relevanceScore": A decimal between 0 and 1 indicating content quality
            5. "contentRating": Predicted rating [G, PG, PG-13, R, NC-17] based on description
            6. "sentiment": Sentiment of the content [POSITIVE, NEUTRAL, NEGATIVE, INSPIRING, EDUCATIONAL]
            
            Return ONLY valid JSON, no additional text.
            """, title, description, tagsStr);
    }

    private List<String> getModelsToTry() {
        List<String> models = new ArrayList<>();
        models.add(geminiConfig.getModel());
        
        if (geminiConfig.getFallbackModels() != null && !geminiConfig.getFallbackModels().isEmpty()) {
            String[] fallbacks = geminiConfig.getFallbackModels().split(",");
            for (String fallback : fallbacks) {
                models.add(fallback.trim());
            }
        }
        
        return models;
    }

    public JsonNode parseEnhancedMetadata(String jsonResponse) {
        try {
            // Extract JSON from response (may contain markdown code blocks)
            String cleanJson = jsonResponse.trim();
            if (cleanJson.startsWith("```json")) {
                cleanJson = cleanJson.substring(7);
            }
            if (cleanJson.startsWith("```")) {
                cleanJson = cleanJson.substring(3);
            }
            if (cleanJson.endsWith("```")) {
                cleanJson = cleanJson.substring(0, cleanJson.length() - 3);
            }
            cleanJson = cleanJson.trim();
            
            return objectMapper.readTree(cleanJson);
        } catch (Exception e) {
            log.error("Failed to parse enhanced metadata JSON", e);
            throw new IllegalArgumentException("Invalid metadata JSON response");
        }
    }
}
