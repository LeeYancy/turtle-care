package com.turtlecare.module.user.controller;

import com.turtlecare.common.ApiResponse;
import com.turtlecare.module.user.dto.LoginRequest;
import com.turtlecare.module.user.dto.LoginResponse;
import com.turtlecare.module.user.dto.RegisterRequest;
import com.turtlecare.module.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@Tag(name = "认证管理", description = "用户注册、登录等认证相关接口")
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @Operation(summary = "用户注册", description = "通过手机号注册新用户，注册成功后直接返回登录Token")
    @PostMapping("/register")
    public ApiResponse<LoginResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ApiResponse.ok(userService.register(request));
    }

    @Operation(summary = "用户登录", description = "通过手机号和密码登录，返回JWT Token")
    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok(userService.login(request));
    }
}
