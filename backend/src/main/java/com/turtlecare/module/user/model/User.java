package com.turtlecare.module.user.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("tc_user")
public class User {
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;
    private String phone;
    private String passwordHash;
    private String nickname;
    private String avatarUrl;
    private Integer experience;      // 养龟经验: 0新手 1进阶 2专业
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
