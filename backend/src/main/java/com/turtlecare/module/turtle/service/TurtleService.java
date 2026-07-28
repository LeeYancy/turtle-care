package com.turtlecare.module.turtle.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.turtlecare.common.exception.BusinessException;
import com.turtlecare.module.ai.repository.HealthRecordMapper;
import com.turtlecare.module.ai.model.HealthRecord;
import com.turtlecare.module.task.service.TaskService;
import com.turtlecare.module.turtle.dto.CreateTurtleRequest;
import com.turtlecare.module.turtle.dto.TurtleResponse;
import com.turtlecare.module.turtle.model.Turtle;
import com.turtlecare.module.turtle.repository.TurtleMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class TurtleService {

    private final TurtleMapper turtleMapper;
    private final HealthRecordMapper healthRecordMapper;
    private final TaskService taskService;

    /**
     * 创建龟档案
     * V1.0 限制：每用户只能有1只活跃龟
     */
    @Transactional
    public TurtleResponse create(Long userId, CreateTurtleRequest request) {
        // V1.0: 限1只活跃龟
        long count = turtleMapper.selectCount(new LambdaQueryWrapper<Turtle>()
                .eq(Turtle::getUserId, userId)
                .eq(Turtle::getIsActive, true));
        if (count > 0) {
            throw BusinessException.badRequest("V1.0仅支持管理1只龟，请先归档现有龟");
        }

        Turtle turtle = new Turtle();
        turtle.setUserId(userId);
        turtle.setName(request.getName());
        turtle.setSpecies(request.getSpecies());
        turtle.setGender(request.getGender());
        turtle.setWeight(request.getWeight());
        turtle.setShellLength(request.getShellLength());
        if (request.getBirthDate() != null && !request.getBirthDate().isEmpty()) {
            turtle.setBirthDate(LocalDate.parse(request.getBirthDate()));
        }
        turtle.setHabitat(request.getHabitat());
        turtle.setNotes(request.getNotes());
        turtle.setIsActive(true);
        turtleMapper.insert(turtle);

        // 自动生成5个默认任务
        taskService.generateDefaultTasks(userId, turtle.getId());

        log.info("Turtle created: {} for user {}", turtle.getName(), userId);
        return TurtleResponse.from(turtle);
    }

    /**
     * 获取用户当前的活跃龟（带最新健康记录）
     */
    public TurtleResponse getByUserId(Long userId) {
        Turtle turtle = turtleMapper.selectOne(new LambdaQueryWrapper<Turtle>()
                .eq(Turtle::getUserId, userId)
                .eq(Turtle::getIsActive, true));
        if (turtle == null) {
            throw BusinessException.notFound("还没有添加龟，快去添加吧");
        }

        TurtleResponse response = TurtleResponse.from(turtle);

        // 附带最新健康记录摘要
        List<HealthRecord> recentHealth = healthRecordMapper.findRecentByTurtleId(turtle.getId(), 1);
        if (!recentHealth.isEmpty()) {
            HealthRecord latest = recentHealth.get(0);
            response.setLatestHealthRisk(latest.getRiskLevel());
            response.setLatestHealthSummary(latest.getAiAnalysis());
        }

        return response;
    }

    /**
     * 列出用户的所有龟
     */
    public List<TurtleResponse> listByUserId(Long userId) {
        return turtleMapper.selectList(new LambdaQueryWrapper<Turtle>()
                        .eq(Turtle::getUserId, userId)
                        .orderByDesc(Turtle::getIsActive)
                        .orderByDesc(Turtle::getCreatedAt))
                .stream()
                .map(TurtleResponse::from)
                .toList();
    }

    /**
     * 更新龟档案
     */
    public TurtleResponse update(Long userId, Long turtleId, CreateTurtleRequest request) {
        Turtle turtle = getOwnedTurtle(userId, turtleId);
        turtle.setName(request.getName());
        turtle.setSpecies(request.getSpecies());
        turtle.setGender(request.getGender());
        turtle.setWeight(request.getWeight());
        turtle.setShellLength(request.getShellLength());
        if (request.getBirthDate() != null && !request.getBirthDate().isEmpty()) {
            turtle.setBirthDate(LocalDate.parse(request.getBirthDate()));
        }
        turtle.setHabitat(request.getHabitat());
        turtle.setNotes(request.getNotes());
        turtleMapper.updateById(turtle);
        log.info("Turtle updated: {} by user {}", turtle.getName(), userId);
        return TurtleResponse.from(turtle);
    }

    /**
     * 软删除龟档案（标记为非活跃）
     * 不会从数据库中物理删除，保留历史数据
     */
    @Transactional
    public void delete(Long userId, Long turtleId) {
        // 先检查龟是否存在且属于该用户
        getOwnedTurtle(userId, turtleId);

        int affected = turtleMapper.softDelete(turtleId, userId);
        if (affected == 0) {
            throw BusinessException.notFound("龟不存在或已归档");
        }
        log.info("Turtle soft-deleted: turtleId={}, userId={}", turtleId, userId);
    }

    /**
     * 验证龟属于当前用户
     */
    private Turtle getOwnedTurtle(Long userId, Long turtleId) {
        Turtle turtle = turtleMapper.selectOne(new LambdaQueryWrapper<Turtle>()
                .eq(Turtle::getId, turtleId)
                .eq(Turtle::getUserId, userId));
        if (turtle == null) {
            throw BusinessException.notFound("龟不存在");
        }
        return turtle;
    }
}
