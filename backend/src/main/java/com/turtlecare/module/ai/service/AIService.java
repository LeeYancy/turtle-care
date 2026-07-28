package com.turtlecare.module.ai.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.turtlecare.common.aspect.RateLimited;
import com.turtlecare.common.exception.BusinessException;
import com.turtlecare.module.ai.dto.HealthAnalysisRequest;
import com.turtlecare.module.ai.dto.HealthAnalysisResponse;
import com.turtlecare.module.ai.dto.ChatRequest;
import com.turtlecare.module.ai.llm.LLMClient;
import com.turtlecare.module.ai.model.HealthRecord;
import com.turtlecare.module.ai.model.ChatMessage;
import com.turtlecare.module.ai.repository.HealthRecordMapper;
import com.turtlecare.module.ai.repository.ChatMessageMapper;
import com.turtlecare.module.turtle.model.Turtle;
import com.turtlecare.module.turtle.repository.TurtleMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class AIService {

    private final LLMClient llmClient;
    private final HealthRecordMapper healthRecordMapper;
    private final ChatMessageMapper chatMessageMapper;
    private final TurtleMapper turtleMapper;
    private final ObjectMapper objectMapper = new ObjectMapper();

    /** 加载的聊天历史条数上限 */
    private static final int CHAT_HISTORY_LIMIT = 10;

    private static final String ANALYSIS_SYSTEM_PROMPT = """
            你是一名资深养龟专家。请根据以下信息分析龟的健康状况。
            
            请按以下格式输出：
            1. 风险等级：低/中/高
            2. 初步判断：对症状的初步分析
            3. 建议措施：具体的处理建议
            4. 是否需要就医：是/否
            
            注意：
            - 如果症状描述不清晰，优先引导用户补充关键信息
            - 如存在需要立即就医的信号（如呼吸困难、持续不进食超过一周），强烈建议就医
            - 不要给出超出你专业范围的诊断
            """;

    private static final String CHAT_SYSTEM_PROMPT = """
            你是一个专业的养龟助手，请用友好、易懂的语言回答养龟相关的问题。
            
            注意事项：
            - 回答要简洁实用，避免过于学术化
            - 涉及到需要就医的情况，明确建议就医
            - 不了解的问题诚实告知，不要编造
            - 语气温暖友好
            """;

    @RateLimited
    public HealthAnalysisResponse analyzeHealth(Long userId, HealthAnalysisRequest request) {
        // 构建龟档案上下文
        Turtle turtle = null;
        if (request.getTurtleId() != null) {
            turtle = turtleMapper.selectById(request.getTurtleId());
        }

        // 获取近期健康记录作为上下文
        List<HealthRecord> recentRecords = List.of();
        if (turtle != null) {
            recentRecords = healthRecordMapper.findRecentByTurtleId(turtle.getId(), 5);
        }

        StringBuilder context = new StringBuilder("【龟档案】\n");
        if (turtle != null) {
            context.append("品种：").append(turtle.getSpecies()).append("\n");
            context.append("体重：").append(turtle.getWeight()).append("g\n");
            context.append("背甲长：").append(turtle.getShellLength()).append("cm\n");
            context.append("饲养环境：").append(turtle.getHabitat()).append("\n");
        } else {
            context.append("(未指定具体龟，将基于通用知识分析)\n");
        }

        context.append("\n【症状描述】\n").append(request.getSymptoms());
        if (request.getEnvironment() != null) {
            context.append("\n\n【环境信息】\n").append(request.getEnvironment());
        }
        if (!recentRecords.isEmpty()) {
            context.append("\n\n【近期健康记录】\n");
            for (HealthRecord r : recentRecords) {
                context.append("- ").append(r.getCreatedAt())
                        .append(" 风险:").append(r.getRiskLevel())
                        .append(" ").append(r.getAiAnalysis()).append("\n");
            }
        }

        HealthAnalysisResponse result = llmClient.analyzeHealth(
                ANALYSIS_SYSTEM_PROMPT, context.toString());

        // 保存分析记录
        HealthRecord record = new HealthRecord();
        record.setUserId(userId);
        record.setTurtleId(request.getTurtleId());
        record.setSymptoms(request.getSymptoms());
        record.setEnvironment(request.getEnvironment());
        record.setRiskLevel(result.getRiskLevel());
        record.setAiAnalysis(result.getDiagnosis());
        record.setRecommendation(result.getRecommendation());
        record.setNeedVet(result.getNeedVet());
        record.setLlmModel(result.getLlmModel());
        healthRecordMapper.insert(record);

        result.setRecordId(record.getId());
        return result;
    }

    /**
     * AI 对话：加载历史上下文 -> 调用LLM -> 保存消息 -> 返回回复
     */
    @RateLimited
    public String chat(Long userId, ChatRequest request) {
        // 1. 加载历史对话作为上下文
        String historyJson = buildChatHistory(userId, request.getTurtleId());

        // 2. 调用LLM
        String response = llmClient.chat(CHAT_SYSTEM_PROMPT, request.getMessage(), historyJson);

        // 3. 保存用户消息
        ChatMessage userMsg = new ChatMessage();
        userMsg.setUserId(userId);
        userMsg.setTurtleId(request.getTurtleId());
        userMsg.setRole("user");
        userMsg.setContent(request.getMessage());
        chatMessageMapper.insert(userMsg);

        // 4. 保存助手回复
        ChatMessage assistantMsg = new ChatMessage();
        assistantMsg.setUserId(userId);
        assistantMsg.setTurtleId(request.getTurtleId());
        assistantMsg.setRole("assistant");
        assistantMsg.setContent(response);
        chatMessageMapper.insert(assistantMsg);

        log.info("Chat completed: userId={}, turtleId={}", userId, request.getTurtleId());
        return response;
    }

    /**
     * 获取健康分析历史
     */
    public List<HealthRecord> getHistory(Long userId, Long turtleId) {
        // 权限校验：验证龟属于当前用户
        Turtle turtle = turtleMapper.selectById(turtleId);
        if (turtle == null || !turtle.getUserId().equals(userId)) {
            throw BusinessException.forbidden("无权访问该龟的健康记录");
        }
        return healthRecordMapper.findRecentByTurtleId(turtleId, 20);
    }

    /**
     * 获取对话历史
     */
    public List<ChatMessage> getChatHistory(Long userId, Long turtleId) {
        if (turtleId != null) {
            return chatMessageMapper.findRecentByUserIdAndTurtleId(userId, turtleId, 50);
        }
        return chatMessageMapper.findRecentByUserId(userId, 50);
    }

    /**
     * 构建聊天历史JSON，作为LLM上下文
     */
    private String buildChatHistory(Long userId, Long turtleId) {
        List<ChatMessage> messages;
        if (turtleId != null) {
            messages = chatMessageMapper.findRecentByUserIdAndTurtleId(userId, turtleId, CHAT_HISTORY_LIMIT);
        } else {
            messages = chatMessageMapper.findRecentByUserId(userId, CHAT_HISTORY_LIMIT);
        }

        if (messages.isEmpty()) {
            return "[]";
        }

        // 反转列表使时间顺序为正序
        Collections.reverse(messages);

        try {
            List<Map<String, String>> historyList = new ArrayList<>();
            for (ChatMessage msg : messages) {
                Map<String, String> entry = new LinkedHashMap<>();
                entry.put("role", msg.getRole());
                entry.put("content", msg.getContent());
                historyList.add(entry);
            }
            return objectMapper.writeValueAsString(historyList);
        } catch (JsonProcessingException e) {
            log.warn("Failed to serialize chat history", e);
            return "[]";
        }
    }
}
