/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/26 12:59
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.content.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.google.genai.Client;
import com.google.genai.types.GenerateContentResponse;
import zw.co.t3ratech.playlizt.content.config.AiProviderConfig;
import zw.co.t3ratech.playlizt.content.config.GeminiConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class GeminiAiService {

    private final GeminiConfig geminiConfig;
    private final AiProviderConfig aiProviderConfig;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .build();

    public String enhanceMetadata(String title, String description, List<String> tags) {
        String prompt = buildMetadataPrompt(title, description, tags);
        List<String> failures = new ArrayList<>();

        for (String provider : aiProviderConfig.orderedProviders()) {
            switch (provider) {
                case "gemini" -> {
                    String result = tryGemini(prompt, failures);
                    if (result != null) {
                        return result;
                    }
                }
                case "nvidia" -> {
                    String result = tryOpenAiCompatibleProvider(
                            "nvidia",
                            aiProviderConfig.getNvidia(),
                            prompt,
                            failures);
                    if (result != null) {
                        return result;
                    }
                }
                case "openrouter" -> {
                    String result = tryOpenAiCompatibleProvider(
                            "openrouter",
                            aiProviderConfig.getOpenrouter(),
                            prompt,
                            failures);
                    if (result != null) {
                        return result;
                    }
                }
                case "openai" -> {
                    String result = tryOpenAiCompatibleProvider(
                            "openai",
                            aiProviderConfig.getOpenai(),
                            prompt,
                            failures);
                    if (result != null) {
                        return result;
                    }
                }
                default -> failures.add("Unsupported AI provider in fallback order: " + provider);
            }
        }

        throw new IllegalStateException(
                "Failed to enhance metadata with all configured AI providers: "
                        + String.join("; ", failures));
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
        if (hasText(geminiConfig.getModel())) {
            models.add(geminiConfig.getModel());
        }

        if (geminiConfig.getFallbackModels() != null && !geminiConfig.getFallbackModels().isEmpty()) {
            String[] fallbacks = geminiConfig.getFallbackModels().split(",");
            for (String fallback : fallbacks) {
                if (hasText(fallback)) {
                    models.add(fallback.trim());
                }
            }
        }

        return models;
    }

    private String tryGemini(String prompt, List<String> failures) {
        if (!hasText(geminiConfig.getKey())) {
            failures.add("Gemini API key is not configured");
            return null;
        }

        Client client = Client.builder()
                .apiKey(geminiConfig.getKey())
                .build();

        for (String model : getModelsToTry()) {
            try {
                log.debug("Attempting Gemini metadata enhancement with model: {}", model);
                GenerateContentResponse response = client.models.generateContent(
                        model,
                        prompt,
                        null
                );

                String result = response.text();
                if (hasText(result)) {
                    log.info("Successfully enhanced metadata using Gemini model: {}", model);
                    return result;
                }
                failures.add("Gemini model returned an empty response: " + model);
            } catch (Exception e) {
                failures.add("Gemini model failed: " + model + " (" + e.getMessage() + ")");
                log.warn("Gemini call failed for model {}: {}", model, e.getMessage());
            }
        }

        return null;
    }

    private String tryOpenAiCompatibleProvider(
            String providerName,
            AiProviderConfig.Provider provider,
            String prompt,
            List<String> failures) {
        if (provider == null || !provider.isConfigured()) {
            failures.add(providerName + " provider is not fully configured");
            return null;
        }

        try {
            ObjectNode requestJson = objectMapper.createObjectNode();
            requestJson.put("model", provider.getModel());
            requestJson.put("max_tokens", geminiConfig.getMaxTokens());
            requestJson.put("temperature", geminiConfig.getTemperature());

            ArrayNode messages = requestJson.putArray("messages");
            messages.addObject()
                    .put("role", "system")
                    .put("content", "Return only valid JSON for Playlizt content metadata enrichment.");
            messages.addObject()
                    .put("role", "user")
                    .put("content", prompt);

            HttpRequest.Builder requestBuilder = HttpRequest.newBuilder()
                    .uri(URI.create(provider.getBaseUrl()))
                    .timeout(Duration.ofSeconds(60))
                    .header("Authorization", "Bearer " + provider.getApiKey())
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(requestJson)));

            if ("openrouter".equals(providerName)) {
                if (hasText(provider.getSiteUrl())) {
                    requestBuilder.header("HTTP-Referer", provider.getSiteUrl());
                }
                if (hasText(provider.getAppName())) {
                    requestBuilder.header("X-Title", provider.getAppName());
                }
            }

            HttpResponse<String> response = httpClient.send(
                    requestBuilder.build(),
                    HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                failures.add(providerName + " returned HTTP " + response.statusCode());
                log.warn("{} metadata provider returned HTTP {}", providerName, response.statusCode());
                return null;
            }

            String content = extractOpenAiCompatibleText(response.body());
            if (hasText(content)) {
                log.info("Successfully enhanced metadata using {} model: {}", providerName, provider.getModel());
                return content;
            }

            failures.add(providerName + " returned an empty response");
            return null;
        } catch (Exception e) {
            failures.add(providerName + " failed (" + e.getMessage() + ")");
            log.warn("{} metadata provider failed: {}", providerName, e.getMessage());
            return null;
        }
    }

    private String extractOpenAiCompatibleText(String responseBody) throws Exception {
        JsonNode root = objectMapper.readTree(responseBody);
        JsonNode content = root.path("choices").path(0).path("message").path("content");
        if (content.isTextual()) {
            return content.asText();
        }
        return null;
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
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
