/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2026/06/11 20:28
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.content.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;
import java.util.List;

@Configuration
@ConfigurationProperties(prefix = "ai.provider")
@Data
public class AiProviderConfig {
    private String fallbackOrder = "gemini,nvidia,openrouter,openai";
    private Provider nvidia = new Provider();
    private Provider openrouter = new Provider();
    private Provider openai = new Provider();

    public List<String> orderedProviders() {
        return Arrays.stream(fallbackOrder.split(","))
                .map(String::trim)
                .filter(provider -> !provider.isBlank())
                .map(String::toLowerCase)
                .toList();
    }

    @Data
    public static class Provider {
        private String apiKey;
        private String model;
        private String baseUrl;
        private String siteUrl;
        private String appName;

        public boolean isConfigured() {
            return hasText(apiKey) && hasText(model) && hasText(baseUrl);
        }

        private boolean hasText(String value) {
            return value != null && !value.trim().isEmpty();
        }
    }
}
