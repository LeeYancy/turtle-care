package com.turtlecare.module.task.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.turtlecare.common.exception.BusinessException;
import com.turtlecare.module.task.dto.TaskResponse;
import com.turtlecare.module.task.model.Task;
import com.turtlecare.module.task.repository.TaskMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskMapper taskMapper;

    /**
     * 获取今日任务
     */
    public List<TaskResponse> getTodayTasks(Long userId) {
        return taskMapper.findByUserIdAndDate(userId, LocalDate.now())
                .stream().map(TaskResponse::from).toList();
    }

    /**
     * 获取本周（7天内）任务
     */
    public List<TaskResponse> getWeekTasks(Long userId) {
        LocalDate today = LocalDate.now();
        return taskMapper.findByUserIdAndDateRange(userId, today, today.plusDays(7))
                .stream().map(TaskResponse::from).toList();
    }

    /**
     * 获取用户所有任务
     */
    public List<TaskResponse> getAll(Long userId) {
        return taskMapper.findByUserId(userId)
                .stream().map(TaskResponse::from).toList();
    }

    /**
     * 完成任务
     */
    public TaskResponse complete(Long userId, Long taskId) {
        Task task = getOwnedTask(userId, taskId);
        if (task.getIsCompleted()) {
            throw BusinessException.badRequest("该任务已完成");
        }
        task.setIsCompleted(true);
        task.setCompletedAt(LocalDateTime.now());
        taskMapper.updateById(task);
        log.info("Task completed: {} for user {}", task.getTitle(), userId);
        return TaskResponse.from(task);
    }

    /**
     * 取消完成任务
     */
    public TaskResponse uncomplete(Long userId, Long taskId) {
        Task task = getOwnedTask(userId, taskId);
        if (!task.getIsCompleted()) {
            throw BusinessException.badRequest("该任务尚未完成");
        }
        task.setIsCompleted(false);
        task.setCompletedAt(null);
        taskMapper.updateById(task);
        log.info("Task uncompleted: {} for user {}", task.getTitle(), userId);
        return TaskResponse.from(task);
    }

    /**
     * 生成默认任务（新用户添加龟后自动调用）
     * 共5个默认任务：3个每日 + 2个每周
     */
    public void generateDefaultTasks(Long userId, Long turtleId) {
        Task[] defaults = {
                buildTask(userId, turtleId, "喂食", "每日按时喂食，观察进食情况", "喂食", "daily"),
                buildTask(userId, turtleId, "检查水质", "观察水质清澈度，如有浑浊或异味请记录", "观察", "daily"),
                buildTask(userId, turtleId, "观察龟的状态", "检查龟的眼睛、背甲、四肢和活动状态", "观察", "daily"),
                buildTask(userId, turtleId, "换水", "根据水质情况更换1/3-1/2的水", "换水", "weekly"),
                buildTask(userId, turtleId, "清洗过滤", "清洗过滤棉，保持过滤效率", "换水", "weekly"),
        };

        for (Task task : defaults) {
            taskMapper.insert(task);
        }
        log.info("Generated {} default tasks for turtle {}", defaults.length, turtleId);
    }

    /**
     * 构建任务对象
     */
    private Task buildTask(Long userId, Long turtleId, String title,
                           String desc, String category, String frequency) {
        Task task = new Task();
        task.setUserId(userId);
        task.setTurtleId(turtleId);
        task.setTitle(title);
        task.setDescription(desc);
        task.setCategory(category);
        task.setFrequency(frequency);
        task.setIsCompleted(false);
        task.setScheduledDate(LocalDate.now());
        return task;
    }

    /**
     * 验证任务属于当前用户
     */
    private Task getOwnedTask(Long userId, Long taskId) {
        Task task = taskMapper.selectOne(new LambdaQueryWrapper<Task>()
                .eq(Task::getId, taskId)
                .eq(Task::getUserId, userId));
        if (task == null) {
            throw BusinessException.notFound("任务不存在");
        }
        return task;
    }
}
