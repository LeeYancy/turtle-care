package com.turtlecare.module.task.dto;

import com.turtlecare.module.task.model.Task;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class TaskResponse {
    private Long id;
    private String title;
    private String description;
    private String category;
    private String frequency;
    private Boolean isCompleted;
    private LocalDate scheduledDate;
    private LocalDateTime completedAt;

    public static TaskResponse from(Task t) {
        return TaskResponse.builder()
                .id(t.getId())
                .title(t.getTitle())
                .description(t.getDescription())
                .category(t.getCategory())
                .frequency(t.getFrequency())
                .isCompleted(t.getIsCompleted())
                .scheduledDate(t.getScheduledDate())
                .completedAt(t.getCompletedAt())
                .build();
    }
}
