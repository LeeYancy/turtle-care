package com.turtlecare.module.user.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.turtlecare.module.user.model.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 用户数据访问层
 */
@Mapper
public interface UserMapper extends BaseMapper<User> {

    /**
     * 根据手机号查询用户
     */
    User findByPhone(@Param("phone") String phone);
}
