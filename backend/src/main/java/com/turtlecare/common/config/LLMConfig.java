package com.turtlecare.common.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "llm")
public class LLMConfig {
    private String provider;
    private OpenAIConfig openai;
    private AnthropicConfig anthropic;

    @Data
    public static class OpenAIConfig {
        private String apiKey;
        private String model;
        private String healthModel;
        private String baseUrl;
    }

    @Data
    public static class AnthropicConfig {
        private String apiKey;
        private String model;
        private String healthModel;
    }
}
