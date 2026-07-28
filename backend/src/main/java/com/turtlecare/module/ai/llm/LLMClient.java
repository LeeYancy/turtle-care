package com.turtlecare.module.ai.llm;

import com.turtlecare.module.ai.dto.HealthAnalysisResponse;

/**
 * LLM调用抽象层，支持 OpenAI / Anthropic / Mock
 */
public interface LLMClient {

    /**
     * 健康分析：同步调用（内部异步化由Service层控制）
     */
    HealthAnalysisResponse analyzeHealth(String prompt, String turtleInfo);

    /**
     * 通用问答
     */
    String chat(String systemPrompt, String userMessage, String historyJson);
}
