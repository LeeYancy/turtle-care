package com.turtlecare.module.ai.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.turtlecare.module.ai.model.HealthRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 健康记录数据访问层
 */
@Mapper
public interface HealthRecordMapper extends BaseMapper<HealthRecord> {

    /**
     * 查询龟的最近N条健康记录
     */
    List<HealthRecord> findRecentByTurtleId(@Param("turtleId") Long turtleId, @Param("limit") int limit);

    /**
     * 查询用户的所有健康分析记录
     */
    List<HealthRecord> findByUserId(@Param("userId") Long userId, @Param("limit") int limit);
}
