package com.turtlecare;

import com.turtlecare.common.security.JwtUtils;
import com.turtlecare.module.user.dto.LoginRequest;
import com.turtlecare.module.user.dto.LoginResponse;
import com.turtlecare.module.user.dto.RegisterRequest;
import com.turtlecare.module.user.model.User;
import com.turtlecare.module.user.repository.UserMapper;
import com.turtlecare.module.user.service.UserService;
import com.turtlecare.common.exception.BusinessException;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * UserService 单元测试
 * 测试用户注册、登录、查询功能
 */
@SpringBootTest
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class UserServiceTest {

    @Autowired
    private UserService userService;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private JwtUtils jwtUtils;

    private static final String TEST_PHONE = "13800138000";
    private static final String TEST_PASSWORD = "Test@123456";
    private static final String TEST_NICKNAME = "测试龟友";

    @BeforeEach
    void setUp() {
        // 清理测试数据（isNotNull确保条件永真，避免空Wrapper异常）
        userMapper.delete(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<User>()
                .isNotNull(User::getId));
    }

    @Test
    @Order(1)
    @DisplayName("用户注册 - 成功创建新用户")
    void testRegisterSuccess() {
        RegisterRequest request = new RegisterRequest();
        request.setPhone(TEST_PHONE);
        request.setPassword(TEST_PASSWORD);
        request.setNickname(TEST_NICKNAME);

        LoginResponse response = userService.register(request);

        assertNotNull(response);
        assertNotNull(response.getToken());
        assertNotNull(response.getUserId());
        assertEquals(TEST_NICKNAME, response.getNickname());

        // 验证JWT token有效性
        Long userId = jwtUtils.getUserId(response.getToken());
        assertEquals(response.getUserId(), userId);

        // 验证数据库中的用户
        User user = userMapper.selectById(response.getUserId());
        assertNotNull(user);
        assertEquals(TEST_PHONE, user.getPhone());
        assertEquals(0, user.getExperience()); // 默认经验值为0
    }

    @Test
    @Order(2)
    @DisplayName("用户注册 - 默认昵称（无昵称时自动生成）")
    void testRegisterWithoutNickname() {
        RegisterRequest request = new RegisterRequest();
        request.setPhone("13800138001");
        request.setPassword(TEST_PASSWORD);

        LoginResponse response = userService.register(request);

        assertNotNull(response);
        // 默认昵称格式: "龟友" + 手机号后4位
        assertTrue(response.getNickname().startsWith("龟友"));
    }

    @Test
    @Order(3)
    @DisplayName("用户注册 - 手机号重复应抛出异常")
    void testRegisterDuplicatePhone() {
        // 先注册一个用户
        RegisterRequest request1 = new RegisterRequest();
        request1.setPhone(TEST_PHONE);
        request1.setPassword(TEST_PASSWORD);
        userService.register(request1);

        // 再用相同手机号注册
        RegisterRequest request2 = new RegisterRequest();
        request2.setPhone(TEST_PHONE);
        request2.setPassword("DifferentPassword1");

        BusinessException ex = assertThrows(BusinessException.class,
                () -> userService.register(request2));
        assertEquals(400, ex.getCode());
        assertTrue(ex.getMessage().contains("已注册"));
    }

    @Test
    @Order(4)
    @DisplayName("用户登录 - 正确凭据登录成功")
    void testLoginSuccess() {
        // 先注册
        RegisterRequest regRequest = new RegisterRequest();
        regRequest.setPhone(TEST_PHONE);
        regRequest.setPassword(TEST_PASSWORD);
        userService.register(regRequest);

        // 登录
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setPhone(TEST_PHONE);
        loginRequest.setPassword(TEST_PASSWORD);

        LoginResponse response = userService.login(loginRequest);

        assertNotNull(response);
        assertNotNull(response.getToken());
        assertNotNull(response.getUserId());
    }

    @Test
    @Order(5)
    @DisplayName("用户登录 - 错误密码应抛出异常")
    void testLoginWrongPassword() {
        // 先注册
        RegisterRequest regRequest = new RegisterRequest();
        regRequest.setPhone(TEST_PHONE);
        regRequest.setPassword(TEST_PASSWORD);
        userService.register(regRequest);

        // 用错误密码登录
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setPhone(TEST_PHONE);
        loginRequest.setPassword("WrongPassword");

        BusinessException ex = assertThrows(BusinessException.class,
                () -> userService.login(loginRequest));
        assertEquals(401, ex.getCode());
    }

    @Test
    @Order(6)
    @DisplayName("用户登录 - 不存在的手机号应抛出异常")
    void testLoginNonExistentPhone() {
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setPhone("13900000000");
        loginRequest.setPassword(TEST_PASSWORD);

        BusinessException ex = assertThrows(BusinessException.class,
                () -> userService.login(loginRequest));
        assertEquals(401, ex.getCode());
    }

    @Test
    @Order(7)
    @DisplayName("查询用户 - 根据ID获取用户成功")
    void testGetByIdSuccess() {
        // 先注册
        RegisterRequest request = new RegisterRequest();
        request.setPhone(TEST_PHONE);
        request.setPassword(TEST_PASSWORD);
        LoginResponse regResponse = userService.register(request);

        User user = userService.getById(regResponse.getUserId());

        assertNotNull(user);
        assertEquals(TEST_PHONE, user.getPhone());
    }

    @Test
    @Order(8)
    @DisplayName("查询用户 - 不存在的ID应抛出异常")
    void testGetByIdNotFound() {
        BusinessException ex = assertThrows(BusinessException.class,
                () -> userService.getById(99999L));
        assertEquals(404, ex.getCode());
        assertTrue(ex.getMessage().contains("不存在"));
    }
}
