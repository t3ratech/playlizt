package com.smatech.playlizt.content.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "gemini.api")
@Data
public class GeminiConfig {
    private String key;
    private String model;
    private String fallbackModels;
}
