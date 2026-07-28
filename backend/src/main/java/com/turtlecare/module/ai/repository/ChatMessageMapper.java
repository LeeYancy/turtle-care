package com.turtlecare.module.ai.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.turtlecare.module.ai.model.ChatMessage;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * AI聊天消息数据访问层
 */
@Mapper
public interface ChatMessageMapper extends BaseMapper<ChatMessage> {

    /**
     * 查询用户与指定龟的最近对话历史
     */
    List<ChatMessage> findRecentByUserIdAndTurtleId(
            @Param("userId") Long userId,
            @Param("turtleId") Long turtleId,
            @Param("limit") int limit
    );

    /**
     * 查询用户的最近对话历史（不限龟）
     */
    List<ChatMessage> findRecentByUserId(
            @Param("userId") Long userId,
            @Param("limit") int limit
    );
}
