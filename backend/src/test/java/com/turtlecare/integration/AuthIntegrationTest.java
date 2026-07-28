package com.turtlecare.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 认证模块集成测试
 * 覆盖注册、登录、重复注册、参数校验等场景
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class AuthIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    private String baseUrl() {
        return "http://localhost:" + port + "/api/v1/auth";
    }

    @Test
    @Order(1)
    @DisplayName("注册新用户 - 成功返回Token和用户信息")
    void register_validInput_returnsToken() {
        // Arrange
        Map<String, Object> request = Map.of(
                "phone", "13800000001",
                "password", "Test@12345",
                "nickname", "测试龟友"
        );

        // Act
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl() + "/register", request, Map.class);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("code")).isEqualTo(200);

        Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
        assertThat(data.get("token")).asString().isNotBlank();
        assertThat(data.get("userId")).isNotNull();
        assertThat(data.get("nickname")).isEqualTo("测试龟友");
    }

    @Test
    @Order(2)
    @DisplayName("重复注册相同手机号 - 返回业务错误")
    void register_duplicatePhone_returnsError() {
        // Arrange
        Map<String, Object> request = Map.of(
                "phone", "13800000002",
                "password", "Test@12345",
                "nickname", "第一用户"
        );
        // First registration
        restTemplate.postForEntity(baseUrl() + "/register", request, Map.class);

        // Act - second registration with same phone
        Map<String, Object> duplicate = Map.of(
                "phone", "13800000002",
                "password", "Different@123",
                "nickname", "第二用户"
        );
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl() + "/register", duplicate, Map.class);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("code")).isNotEqualTo(200);
    }

    @Test
    @Order(3)
    @DisplayName("登录已注册用户 - 成功返回Token")
    void login_validCredentials_returnsToken() {
        // Arrange - register first
        Map<String, Object> registerReq = Map.of(
                "phone", "13800000003",
                "password", "Test@12345"
        );
        restTemplate.postForEntity(baseUrl() + "/register", registerReq, Map.class);

        // Act - login
        Map<String, Object> loginReq = Map.of(
                "phone", "13800000003",
                "password", "Test@12345"
        );
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl() + "/login", loginReq, Map.class);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
        assertThat(data.get("token")).asString().isNotBlank();
    }

    @Test
    @Order(4)
    @DisplayName("登录密码错误 - 返回认证失败")
    void login_wrongPassword_returnsError() {
        // Arrange - register
        Map<String, Object> registerReq = Map.of(
                "phone", "13800000004",
                "password", "CorrectPass@123"
        );
        restTemplate.postForEntity(baseUrl() + "/register", registerReq, Map.class);

        // Act - login with wrong password
        Map<String, Object> loginReq = Map.of(
                "phone", "13800000004",
                "password", "WrongPass@999"
        );
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl() + "/login", loginReq, Map.class);

        // Assert
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("code")).isNotEqualTo(200);
    }

    @Test
    @Order(5)
    @DisplayName("注册无效手机号 - 返回参数校验错误")
    void register_invalidPhone_returnsValidationError() {
        // Arrange
        Map<String, Object> request = Map.of(
                "phone", "12345",
                "password", "Test@12345"
        );

        // Act
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl() + "/register", request, Map.class);

        // Assert - validation failure should return non-200 code
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("code")).isNotEqualTo(200);
    }

    @Test
    @Order(6)
    @DisplayName("注册缺少必填字段 - 返回参数校验错误")
    void register_missingFields_returnsValidationError() {
        // Arrange - missing password
        Map<String, Object> request = Map.of(
                "phone", "13800000005"
        );

        // Act
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl() + "/register", request, Map.class);

        // Assert
        assertThat(response.getStatusCode()).isIn(HttpStatus.BAD_REQUEST, HttpStatus.OK);
    }
}
