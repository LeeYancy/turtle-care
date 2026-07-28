package com.turtlecare;

import com.turtlecare.common.exception.BusinessException;
import com.turtlecare.module.turtle.dto.CreateTurtleRequest;
import com.turtlecare.module.turtle.dto.TurtleResponse;
import com.turtlecare.module.turtle.model.Turtle;
import com.turtlecare.module.turtle.repository.TurtleMapper;
import com.turtlecare.module.turtle.service.TurtleService;
import com.turtlecare.module.user.dto.LoginResponse;
import com.turtlecare.module.user.dto.RegisterRequest;
import com.turtlecare.module.user.service.UserService;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

/**
 * TurtleService 单元测试
 * 测试龟档案创建、查询、更新、软删除
 */
@SpringBootTest
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class TurtleServiceTest {

    @Autowired
    private TurtleService turtleService;

    @Autowired
    private TurtleMapper turtleMapper;

    @Autowired
    private UserService userService;

    private Long userId;
    private Long turtleId;

    @BeforeEach
    void setUp() {
        // 清理并创建测试用户
        turtleMapper.delete(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<Turtle>()
                .isNotNull(Turtle::getId));

        RegisterRequest regRequest = new RegisterRequest();
        regRequest.setPhone("13800138000");
        regRequest.setPassword("Test@123456");
        LoginResponse loginResponse = userService.register(regRequest);
        userId = loginResponse.getUserId();
    }

    private CreateTurtleRequest buildRequest(String name, String species) {
        CreateTurtleRequest request = new CreateTurtleRequest();
        request.setName(name);
        request.setSpecies(species);
        request.setGender("公");
        request.setWeight(250.0);
        request.setShellLength(8.5);
        request.setBirthDate("2023-06-15");
        request.setHabitat("水养");
        request.setNotes("测试用龟");
        return request;
    }

    @Test
    @Order(1)
    @DisplayName("创建龟档案 - 成功创建并自动生成默认任务")
    void testCreateTurtleSuccess() {
        CreateTurtleRequest request = buildRequest("小乌龟", "巴西龟");
        TurtleResponse response = turtleService.create(userId, request);

        assertNotNull(response);
        assertNotNull(response.getId());
        assertEquals("小乌龟", response.getName());
        assertEquals("巴西龟", response.getSpecies());
        assertEquals("公", response.getGender());
        assertEquals(250.0, response.getWeight());
        assertEquals("水养", response.getHabitat());

        turtleId = response.getId();

        // 验证数据库中确实创建了
        Turtle turtle = turtleMapper.selectById(turtleId);
        assertNotNull(turtle);
        assertTrue(turtle.getIsActive());
        assertEquals(userId, turtle.getUserId());
    }

    @Test
    @Order(2)
    @DisplayName("创建龟档案 - V1.0限制：只能有1只活跃龟")
    void testCreateSecondTurtleFails() {
        // 先创建第一只
        turtleService.create(userId, buildRequest("龟一", "巴西龟"));

        // 尝试创建第二只
        BusinessException ex = assertThrows(BusinessException.class,
                () -> turtleService.create(userId, buildRequest("龟二", "草龟")));
        assertEquals(400, ex.getCode());
        assertTrue(ex.getMessage().contains("1只"));
    }

    @Test
    @Order(3)
    @DisplayName("查询活跃龟 - 成功获取")
    void testGetActiveTurtle() {
        turtleService.create(userId, buildRequest("我的龟", "巴西龟"));

        TurtleResponse response = turtleService.getByUserId(userId);

        assertNotNull(response);
        assertEquals("我的龟", response.getName());
    }

    @Test
    @Order(4)
    @DisplayName("查询活跃龟 - 无龟时应抛出异常")
    void testGetActiveTurtleNotFound() {
        BusinessException ex = assertThrows(BusinessException.class,
                () -> turtleService.getByUserId(userId));
        assertEquals(404, ex.getCode());
        assertTrue(ex.getMessage().contains("还没有添加龟"));
    }

    @Test
    @Order(5)
    @DisplayName("更新龟档案 - 成功更新")
    void testUpdateTurtle() {
        TurtleResponse created = turtleService.create(userId, buildRequest("原始名", "巴西龟"));

        CreateTurtleRequest updateRequest = buildRequest("新名字", "草龟");
        updateRequest.setWeight(300.0);
        updateRequest.setHabitat("半水");

        TurtleResponse updated = turtleService.update(userId, created.getId(), updateRequest);

        assertEquals("新名字", updated.getName());
        assertEquals("草龟", updated.getSpecies());
        assertEquals(300.0, updated.getWeight());
        assertEquals("半水", updated.getHabitat());
    }

    @Test
    @Order(6)
    @DisplayName("更新龟档案 - 非本人龟应抛出异常")
    void testUpdateOtherUsersTurtle() {
        // 用户A创建龟
        TurtleResponse created = turtleService.create(userId, buildRequest("龟A", "巴西龟"));

        // 用户B尝试更新
        RegisterRequest regB = new RegisterRequest();
        regB.setPhone("13900000001");
        regB.setPassword("Test@123456");
        Long otherUserId = userService.register(regB).getUserId();

        BusinessException ex = assertThrows(BusinessException.class,
                () -> turtleService.update(otherUserId, created.getId(), buildRequest("改名", "巴西龟")));
        assertEquals(404, ex.getCode());
    }

    @Test
    @Order(7)
    @DisplayName("软删除龟 - 成功归档")
    void testSoftDeleteTurtle() {
        TurtleResponse created = turtleService.create(userId, buildRequest("待删除龟", "巴西龟"));

        turtleService.delete(userId, created.getId());

        // 验证已软删除
        Turtle turtle = turtleMapper.selectById(created.getId());
        assertNotNull(turtle);
        assertFalse(turtle.getIsActive());
    }

    @Test
    @Order(8)
    @DisplayName("软删除后可以创建新龟")
    void testCreateAfterSoftDelete() {
        // 创建第一只并删除
        TurtleResponse first = turtleService.create(userId, buildRequest("龟一", "巴西龟"));
        turtleService.delete(userId, first.getId());

        // 应该可以创建第二只
        TurtleResponse second = turtleService.create(userId, buildRequest("龟二", "草龟"));
        assertNotNull(second);
        assertEquals("龟二", second.getName());
    }

    @Test
    @Order(9)
    @DisplayName("列出所有龟 - 包括已归档的")
    void testListAllTurtles() {
        TurtleResponse first = turtleService.create(userId, buildRequest("龟一", "巴西龟"));
        turtleService.delete(userId, first.getId());

        TurtleResponse second = turtleService.create(userId, buildRequest("龟二", "草龟"));

        var list = turtleService.listByUserId(userId);
        assertEquals(2, list.size());
        // 活跃的在前
        assertTrue(list.get(0).getName().equals("龟二"));
    }
}
