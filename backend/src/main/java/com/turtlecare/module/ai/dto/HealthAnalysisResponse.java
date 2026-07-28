package com.turtlecare.module.ai.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class HealthAnalysisResponse {
    private Long recordId;
    private String riskLevel;         // 低/中/高
    private String summary;           // 分析摘要
    private String diagnosis;         // 初步判断
    private String recommendation;    // 建议措施
    private Boolean needVet;          // 是否需要就医
    private String llmModel;
}
