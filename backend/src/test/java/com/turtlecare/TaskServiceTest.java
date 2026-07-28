package com.turtlecare;

import com.turtlecare.common.exception.BusinessException;
import com.turtlecare.module.task.dto.TaskResponse;
import com.turtlecare.module.task.model.Task;
import com.turtlecare.module.task.repository.TaskMapper;
import com.turtlecare.module.task.service.TaskService;
import com.turtlecare.module.user.dto.LoginResponse;
import com.turtlecare.module.user.dto.RegisterRequest;
import com.turtlecare.module.user.service.UserService;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * TaskService 单元测试
 * 测试任务生成、查询、完成、取消完成
 */
@SpringBootTest
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class TaskServiceTest {

    @Autowired
    private TaskService taskService;

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private UserService userService;

    private Long userId;
    private Long turtleId = 1L; // 使用固定ID模拟

    @BeforeEach
    void setUp() {
        // 清理测试数据
        taskMapper.delete(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<Task>()
                .isNotNull(Task::getId));

        // 创建测试用户
        RegisterRequest regRequest = new RegisterRequest();
        regRequest.setPhone("13800138000");
        regRequest.setPassword("Test@123456");
        LoginResponse loginResponse = userService.register(regRequest);
        userId = loginResponse.getUserId();
    }

    @Test
    @Order(1)
    @DisplayName("生成默认任务 - 应创建5个任务")
    void testGenerateDefaultTasks() {
        taskService.generateDefaultTasks(userId, turtleId);

        List<TaskResponse> tasks = taskService.getTodayTasks(userId);

        assertNotNull(tasks);
        assertEquals(5, tasks.size());

        // 验证任务内容
        List<String> titles = tasks.stream().map(TaskResponse::getTitle).toList();
        assertTrue(titles.contains("喂食"));
        assertTrue(titles.contains("检查水质"));
        assertTrue(titles.contains("观察龟的状态"));
        assertTrue(titles.contains("换水"));
        assertTrue(titles.contains("清洗过滤"));

        // 验证所有任务初始均为未完成
        assertTrue(tasks.stream().noneMatch(TaskResponse::getIsCompleted));
    }

    @Test
    @Order(2)
    @DisplayName("获取今日任务 - 成功获取")
    void testGetTodayTasks() {
        taskService.generateDefaultTasks(userId, turtleId);

        List<TaskResponse> tasks = taskService.getTodayTasks(userId);

        assertEquals(5, tasks.size());
        // 未完成的任务应该排在前面
        assertFalse(tasks.get(0).getIsCompleted());
    }

    @Test
    @Order(3)
    @DisplayName("获取所有任务 - 成功获取")
    void testGetAllTasks() {
        taskService.generateDefaultTasks(userId, turtleId);

        List<TaskResponse> tasks = taskService.getAll(userId);

        assertEquals(5, tasks.size());
    }

    @Test
    @Order(4)
    @DisplayName("完成任务 - 成功完成")
    void testCompleteTask() {
        taskService.generateDefaultTasks(userId, turtleId);
        List<TaskResponse> tasks = taskService.getTodayTasks(userId);
        Long taskId = tasks.get(0).getId();

        TaskResponse completed = taskService.complete(userId, taskId);

        assertTrue(completed.getIsCompleted());
        assertNotNull(completed.getCompletedAt());

        // 验证数据库中确实更新了
        Task task = taskMapper.selectById(taskId);
        assertTrue(task.getIsCompleted());
        assertNotNull(task.getCompletedAt());
    }

    @Test
    @Order(5)
    @DisplayName("完成任务 - 重复完成应抛出异常")
    void testCompleteAlreadyCompletedTask() {
        taskService.generateDefaultTasks(userId, turtleId);
        List<TaskResponse> tasks = taskService.getTodayTasks(userId);
        Long taskId = tasks.get(0).getId();

        // 第一次完成
        taskService.complete(userId, taskId);

        // 第二次完成应失败
        BusinessException ex = assertThrows(BusinessException.class,
                () -> taskService.complete(userId, taskId));
        assertEquals(400, ex.getCode());
        assertTrue(ex.getMessage().contains("已完成"));
    }

    @Test
    @Order(6)
    @DisplayName("取消完成任务 - 成功取消")
    void testUncompleteTask() {
        taskService.generateDefaultTasks(userId, turtleId);
        List<TaskResponse> tasks = taskService.getTodayTasks(userId);
        Long taskId = tasks.get(0).getId();

        // 先完成
        taskService.complete(userId, taskId);

        // 再取消
        TaskResponse uncompleted = taskService.uncomplete(userId, taskId);

        assertFalse(uncompleted.getIsCompleted());
        assertNull(uncompleted.getCompletedAt());
    }

    @Test
    @Order(7)
    @DisplayName("取消完成任务 - 未完成的任务取消应抛出异常")
    void testUncompleteNotCompletedTask() {
        taskService.generateDefaultTasks(userId, turtleId);
        List<TaskResponse> tasks = taskService.getTodayTasks(userId);
        Long taskId = tasks.get(0).getId();

        BusinessException ex = assertThrows(BusinessException.class,
                () -> taskService.uncomplete(userId, taskId));
        assertEquals(400, ex.getCode());
        assertTrue(ex.getMessage().contains("尚未完成"));
    }

    @Test
    @Order(8)
    @DisplayName("完成任务 - 非本人任务应抛出异常")
    void testCompleteOtherUsersTask() {
        taskService.generateDefaultTasks(userId, turtleId);
        List<TaskResponse> tasks = taskService.getTodayTasks(userId);
        Long taskId = tasks.get(0).getId();

        // 创建另一个用户
        RegisterRequest regB = new RegisterRequest();
        regB.setPhone("13900000001");
        regB.setPassword("Test@123456");
        Long otherUserId = userService.register(regB).getUserId();

        BusinessException ex = assertThrows(BusinessException.class,
                () -> taskService.complete(otherUserId, taskId));
        assertEquals(404, ex.getCode());
    }

    @Test
    @Order(9)
    @DisplayName("获取本周任务 - 应包含今日任务")
    void testGetWeekTasks() {
        taskService.generateDefaultTasks(userId, turtleId);

        List<TaskResponse> tasks = taskService.getWeekTasks(userId);

        assertNotNull(tasks);
        assertTrue(tasks.size() >= 5);
    }
}
