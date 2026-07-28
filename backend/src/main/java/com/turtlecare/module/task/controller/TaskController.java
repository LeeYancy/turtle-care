package com.turtlecare.module.task.controller;

import com.turtlecare.common.ApiResponse;
import com.turtlecare.module.task.dto.TaskResponse;
import com.turtlecare.module.task.service.TaskService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "任务管理", description = "养龟日常任务的查询、完成等接口")
@RestController
@RequestMapping("/api/v1/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    @Operation(summary = "获取今日任务", description = "获取当前登录用户的今日养龟任务列表")
    @GetMapping("/today")
    public ApiResponse<List<TaskResponse>> getToday(Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(taskService.getTodayTasks(userId));
    }

    @Operation(summary = "获取本周任务", description = "获取当前登录用户的本周养龟任务列表")
    @GetMapping("/week")
    public ApiResponse<List<TaskResponse>> getWeek(Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(taskService.getWeekTasks(userId));
    }

    @Operation(summary = "完成任务", description = "标记指定任务为已完成")
    @PostMapping("/{taskId}/complete")
    public ApiResponse<TaskResponse> complete(Authentication auth,
                                               @PathVariable Long taskId) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(taskService.complete(userId, taskId));
    }

    @Operation(summary = "取消完成任务", description = "将已完成的任务标记为未完成")
    @PostMapping("/{taskId}/uncomplete")
    public ApiResponse<TaskResponse> uncomplete(Authentication auth,
                                                 @PathVariable Long taskId) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(taskService.uncomplete(userId, taskId));
    }
}
