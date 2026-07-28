package com.turtlecare.common.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "oss")
public class OSSConfig {
    private String provider;
    private AliyunConfig aliyun;

    @Data
    public static class AliyunConfig {
        private String endpoint;
        private String accessKeyId;
        private String accessKeySecret;
        private String bucket;
    }
}
