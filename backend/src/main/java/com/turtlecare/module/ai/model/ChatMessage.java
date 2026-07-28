package com.turtlecare.module.ai.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("tc_chat_message")
public class ChatMessage {
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;
    private Long userId;
    private Long turtleId;
    private String role;              // user / assistant
    private String content;
    private String model;
    private Integer latencyMs;
    private LocalDateTime createdAt;
}
