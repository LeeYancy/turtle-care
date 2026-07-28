package com.turtlecare.common.aspect;

import com.turtlecare.common.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

/**
 * AI接口限流切面
 * 每人每天最多50次，每小时恢复5次
 */
@Slf4j
@Aspect
@Component
@RequiredArgsConstructor
public class RateLimitAspect {

    private final RedisTemplate<String, Object> redisTemplate;

    @Value("${rate-limit.ai.capacity:50}")
    private int capacity;

    @Value("${rate-limit.ai.refill-rate:5}")
    private int refillRate;

    @Around("@annotation(com.turtlecare.common.aspect.RateLimited)")
    public Object rateLimit(ProceedingJoinPoint joinPoint) throws Throwable {
        // V1.0: 简化实现，后续用bucket4j完善
        Long userId = getCurrentUserId();
        String key = "rate:ai:user:" + userId + ":day";

        Long count = redisTemplate.opsForValue().increment(key);
        if (count == null || count == 1) {
            redisTemplate.expire(key, 24, TimeUnit.HOURS);
        }

        if (count != null && count > capacity) {
            throw BusinessException.rateLimited(
                    "今日AI调用次数已达上限(" + capacity + "次)，请明天再试");
        }

        return joinPoint.proceed();
    }

    private Long getCurrentUserId() {
        // TODO: 从SecurityContext获取当前用户ID
        return 1L;
    }
}
