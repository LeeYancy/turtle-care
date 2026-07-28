package com.turtlecare.module.turtle.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("tc_turtle")
public class Turtle {
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;
    private Long userId;
    private String name;
    private String species;           // 品种名
    private String speciesCn;         // 中文品种名
    private String gender;            // 公/母/未知
    private Double weight;            // 克
    private Double shellLength;       // 背甲长 cm
    private LocalDate birthDate;      // 出生/入手日期
    private String photoUrl;          // 照片OSS地址
    private String habitat;           // 饲养环境: 水养/半水/陆养
    private String notes;             // 备注
    private Boolean isActive;         // 是否活跃（用于V1.0单龟限制）
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
