package com.turtlecare.module.ai.controller;

import com.turtlecare.common.ApiResponse;
import com.turtlecare.module.ai.dto.ChatRequest;
import com.turtlecare.module.ai.dto.HealthAnalysisRequest;
import com.turtlecare.module.ai.dto.HealthAnalysisResponse;
import com.turtlecare.module.ai.model.HealthRecord;
import com.turtlecare.module.ai.service.AIService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "AI智能助手", description = "AI健康分析、智能问答等接口")
@RestController
@RequestMapping("/api/v1/ai")
@RequiredArgsConstructor
public class AIController {

    private final AIService aiService;

    @Operation(summary = "AI健康分析", description = "根据症状描述和环境信息，AI分析龟的健康状况并给出建议")
    @PostMapping("/health/analyze")
    public ApiResponse<HealthAnalysisResponse> analyzeHealth(
            Authentication auth,
            @Valid @RequestBody HealthAnalysisRequest request) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(aiService.analyzeHealth(userId, request));
    }

    @Operation(summary = "AI智能问答", description = "与AI助手进行养龟相关的智能问答对话")
    @PostMapping("/chat")
    public ApiResponse<String> chat(
            Authentication auth,
            @Valid @RequestBody ChatRequest request) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(aiService.chat(userId, request));
    }

    @Operation(summary = "获取健康分析历史", description = "根据龟ID获取该龟的健康分析历史记录")
    @GetMapping("/health/history/{turtleId}")
    public ApiResponse<List<HealthRecord>> getHistory(
            Authentication auth,
            @PathVariable Long turtleId) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(aiService.getHistory(userId, turtleId));
    }
}
