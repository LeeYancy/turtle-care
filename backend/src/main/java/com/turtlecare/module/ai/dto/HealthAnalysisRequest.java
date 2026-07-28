package com.turtlecare.module.ai.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class HealthAnalysisRequest {
    @NotBlank(message = "请描述龟的症状")
    private String symptoms;

    private String environment;       // JSON: {"waterTemp":26,"ph":7.2,...}
    private Long turtleId;
}
