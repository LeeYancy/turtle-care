package com.turtlecare.module.task.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.turtlecare.module.task.model.Task;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.util.List;

/**
 * 养龟任务数据访问层
 */
@Mapper
public interface TaskMapper extends BaseMapper<Task> {

    /**
     * 查询用户指定日期的任务
     */
    List<Task> findByUserIdAndDate(@Param("userId") Long userId, @Param("date") LocalDate date);

    /**
     * 查询用户指定日期范围内的任务
     */
    List<Task> findByUserIdAndDateRange(@Param("userId") Long userId, @Param("start") LocalDate start, @Param("end") LocalDate end);

    /**
     * 查询用户的所有任务（按日期倒序）
     */
    List<Task> findByUserId(@Param("userId") Long userId);

    /**
     * 查询龟的任务数量
     */
    int countByTurtleId(@Param("turtleId") Long turtleId);
}
