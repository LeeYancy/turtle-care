package com.turtlecare.module.task.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("tc_task")
public class Task {
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;
    private Long userId;
    private Long turtleId;
    private String title;
    private String description;
    private String category;          // 喂食/换水/观察/其他
    private String frequency;         // daily/weekly/monthly
    private Boolean isCompleted;
    private LocalDate scheduledDate;
    private LocalDateTime completedAt;
    private LocalDateTime createdAt;
}
