package com.turtlecare.module.ai.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ChatRequest {
    @NotBlank(message = "消息内容不能为空")
    private String message;

    private Long turtleId;
}
