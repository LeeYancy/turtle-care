-- ============================================
-- TurtleCare V1.0 Initial Schema
-- Flyway Migration V1
-- ============================================

-- 用户表
CREATE TABLE IF NOT EXISTS tc_user (
    id BIGINT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(50),
    avatar_url VARCHAR(500),
    experience INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 龟档案表
CREATE TABLE IF NOT EXISTS tc_turtle (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES tc_user(id),
    name VARCHAR(50) NOT NULL,
    species VARCHAR(100),
    species_cn VARCHAR(100),
    gender VARCHAR(10) DEFAULT '未知',
    weight DOUBLE PRECISION,
    shell_length DOUBLE PRECISION,
    birth_date DATE,
    photo_url VARCHAR(500),
    habitat VARCHAR(50),
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_turtle_user ON tc_turtle(user_id);

-- 健康分析记录
CREATE TABLE IF NOT EXISTS tc_health_record (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES tc_user(id),
    turtle_id BIGINT REFERENCES tc_turtle(id),
    symptoms TEXT NOT NULL,
    environment TEXT,
    ai_analysis TEXT,
    risk_level VARCHAR(10),
    recommendation TEXT,
    need_vet BOOLEAN DEFAULT FALSE,
    llm_model VARCHAR(50),
    llm_latency_ms INTEGER,
    llm_cost VARCHAR(20),
    user_rating INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_health_record_turtle ON tc_health_record(turtle_id, created_at DESC);

-- AI聊天消息
CREATE TABLE IF NOT EXISTS tc_chat_message (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES tc_user(id),
    turtle_id BIGINT,
    role VARCHAR(10) NOT NULL,
    content TEXT NOT NULL,
    model VARCHAR(50),
    latency_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_message_user ON tc_chat_message(user_id, created_at DESC);

-- 任务表
CREATE TABLE IF NOT EXISTS tc_task (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES tc_user(id),
    turtle_id BIGINT REFERENCES tc_turtle(id),
    title VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(20),
    frequency VARCHAR(20),
    is_completed BOOLEAN DEFAULT FALSE,
    scheduled_date DATE NOT NULL,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_task_user_date ON tc_task(user_id, scheduled_date);

-- 健康评分表 (V1.0简化版)
CREATE TABLE IF NOT EXISTS tc_health_score (
    id BIGINT PRIMARY KEY,
    turtle_id BIGINT NOT NULL REFERENCES tc_turtle(id),
    score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
    appetite_score INTEGER,
    activity_score INTEGER,
    appearance_score INTEGER,
    environment_score INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_health_score_turtle ON tc_health_score(turtle_id, created_at DESC);
