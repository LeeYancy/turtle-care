package com.turtlecare.module.ai.llm;

import com.turtlecare.module.ai.dto.HealthAnalysisResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Mock LLM Client: 开发阶段不使用真实API时的替代实现
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "llm.provider", havingValue = "mock", matchIfMissing = true)
public class MockLLMClient implements LLMClient {

    @Override
    public HealthAnalysisResponse analyzeHealth(String prompt, String turtleInfo) {
        log.info("[MOCK] Health analysis called. Prompt length: {}", prompt.length());
        log.debug("[MOCK] Prompt: {}", prompt);
        log.debug("[MOCK] Turtle info: {}", turtleInfo);

        return HealthAnalysisResponse.builder()
                .riskLevel("低")
                .summary("模拟分析结果：根据您描述的症状，目前看起来没有严重问题。")
                .diagnosis("建议持续观察，保持水质清洁。")
                .recommendation("1. 保持水温在24-28℃\n2. 每日观察进食情况\n3. 如3天后无改善请就医")
                .needVet(false)
                .llmModel("mock-model")
                .build();
    }

    @Override
    public String chat(String systemPrompt, String userMessage, String historyJson) {
        log.info("[MOCK] Chat called. Message: {}", userMessage);
        return "这是模拟回复。在实际部署中，这里会调用真实的LLM API。您的问题已被记录，我会尽快学习更多养龟知识来帮助您。";
    }
}
