package com.turtlecare.module.ai.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("tc_health_record")
public class HealthRecord {
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;
    private Long userId;
    private Long turtleId;
    private String symptoms;          // 用户输入的症状描述
    private String environment;       // 环境信息(JSON)
    private String aiAnalysis;        // AI分析结果(JSON)
    private String riskLevel;         // 低/中/高
    private String recommendation;    // 建议措施
    private Boolean needVet;          // 是否需要就医
    private String llmModel;          // 使用的模型
    private Integer llmLatencyMs;     // LLM延迟
    private String llmCost;           // LLM成本
    private Integer userRating;       // 用户评分 1-5
    private LocalDateTime createdAt;
}
