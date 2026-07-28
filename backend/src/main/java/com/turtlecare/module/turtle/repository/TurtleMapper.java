package com.turtlecare.module.turtle.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.turtlecare.module.turtle.model.Turtle;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 龟档案数据访问层
 */
@Mapper
public interface TurtleMapper extends BaseMapper<Turtle> {

    /**
     * 查询用户的所有活跃龟（V1.0 只有1只）
     */
    List<Turtle> findActiveByUserId(@Param("userId") Long userId);

    /**
     * 软删除：将龟标记为非活跃
     */
    int softDelete(@Param("id") Long id, @Param("userId") Long userId);
}
