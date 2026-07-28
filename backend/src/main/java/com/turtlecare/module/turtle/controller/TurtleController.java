package com.turtlecare.module.turtle.controller;

import com.turtlecare.common.ApiResponse;
import com.turtlecare.module.turtle.dto.CreateTurtleRequest;
import com.turtlecare.module.turtle.dto.TurtleResponse;
import com.turtlecare.module.turtle.service.TurtleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "龟档案管理", description = "龟档案的创建、查询、更新等接口")
@RestController
@RequestMapping("/api/v1/turtles")
@RequiredArgsConstructor
public class TurtleController {

    private final TurtleService turtleService;

    @Operation(summary = "创建龟档案", description = "为当前登录用户创建一个新的龟档案")
    @PostMapping
    public ApiResponse<TurtleResponse> create(Authentication auth,
                                               @Valid @RequestBody CreateTurtleRequest request) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(turtleService.create(userId, request));
    }

    @Operation(summary = "获取当前活跃龟档案", description = "获取当前登录用户的活跃龟档案")
    @GetMapping("/active")
    public ApiResponse<TurtleResponse> getActive(Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(turtleService.getByUserId(userId));
    }

    @Operation(summary = "获取龟档案列表", description = "获取当前登录用户的所有龟档案列表")
    @GetMapping
    public ApiResponse<List<TurtleResponse>> list(Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(turtleService.listByUserId(userId));
    }

    @Operation(summary = "更新龟档案", description = "根据龟ID更新龟档案信息")
    @PutMapping("/{turtleId}")
    public ApiResponse<TurtleResponse> update(Authentication auth,
                                               @PathVariable Long turtleId,
                                               @Valid @RequestBody CreateTurtleRequest request) {
        Long userId = (Long) auth.getPrincipal();
        return ApiResponse.ok(turtleService.update(userId, turtleId, request));
    }
}
