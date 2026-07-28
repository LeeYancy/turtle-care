package com.turtlecare.module.user.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.turtlecare.common.exception.BusinessException;
import com.turtlecare.common.security.JwtUtils;
import com.turtlecare.module.user.dto.LoginRequest;
import com.turtlecare.module.user.dto.LoginResponse;
import com.turtlecare.module.user.dto.RegisterRequest;
import com.turtlecare.module.user.model.User;
import com.turtlecare.module.user.repository.UserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;

    public LoginResponse register(RegisterRequest request) {
        // Check if phone already exists
        if (userMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getPhone, request.getPhone())) > 0) {
            throw BusinessException.badRequest("该手机号已注册");
        }

        User user = new User();
        user.setPhone(request.getPhone());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setNickname(request.getNickname() != null
                ? request.getNickname() : "龟友" + request.getPhone().substring(7));
        user.setExperience(0); // default: novice
        userMapper.insert(user);

        log.info("New user registered: {}", user.getPhone());
        return buildLoginResponse(user);
    }

    public LoginResponse login(LoginRequest request) {
        User user = userMapper.selectOne(new LambdaQueryWrapper<User>()
                .eq(User::getPhone, request.getPhone()));

        if (user == null || !passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw BusinessException.unauthorized("手机号或密码错误");
        }

        return buildLoginResponse(user);
    }

    public User getById(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw BusinessException.notFound("用户不存在");
        }
        return user;
    }

    private LoginResponse buildLoginResponse(User user) {
        String token = jwtUtils.generateToken(user.getId(), user.getPhone());
        return LoginResponse.builder()
                .token(token)
                .userId(user.getId())
                .nickname(user.getNickname())
                .build();
    }
}
