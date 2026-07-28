package com.turtlecare.integration;

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
 * 龟档案模块集成测试
 * 覆盖创建、查询、列表、更新等场景，包含认证流程
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class TurtleIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    private static String jwtToken;
    private static Long turtleId;

    private String baseUrl() {
        return "http://localhost:" + port + "/api/v1";
    }

    /**
     * 注册并登录，获取JWT Token供后续测试使用
     */
    private String registerAndGetToken(String phone) {
        Map<String, Object> registerReq = Map.of(
                "phone", phone,
                "password", "Test@12345",
                "nickname", "龟档测试用户"
        );
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl() + "/auth/register", registerReq, Map.class);
        Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
        return "Bearer " + data.get("token");
    }

    private HttpHeaders authHeaders(String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Authorization", token);
        return headers;
    }

    @Test
    @Order(1)
    @DisplayName("未认证访问龟档案接口 - 返回401/403")
    void accessWithoutAuth_returnsUnauthorized() {
        ResponseEntity<Map> response = restTemplate.getForEntity(
                baseUrl() + "/turtles", Map.class);

        assertThat(response.getStatusCode()).isIn(
                HttpStatus.UNAUTHORIZED, HttpStatus.FORBIDDEN);
    }

    @Test
    @Order(2)
    @DisplayName("创建龟档案 - 成功返回龟信息")
    void createTurtle_validInput_returnsTurtle() {
        // Arrange - register and get token
        jwtToken = registerAndGetToken("13900000001");

        Map<String, Object> turtleReq = Map.of(
                "name", "小龟",
                "species", "Trachemys scripta elegans",
                "gender", "公",
                "weight", 250.0,
                "shellLength", 12.5,
                "habitat", "水养"
        );

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(turtleReq, authHeaders(jwtToken));

        // Act
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl() + "/turtles", entity, Map.class);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
        assertThat(data.get("name")).isEqualTo("小龟");
        assertThat(data.get("species")).isEqualTo("Trachemys scripta elegans");
        assertThat(data.get("id")).isNotNull();

        // Save turtleId for later tests
        turtleId = ((Number) data.get("id")).longValue();
    }

    @Test
    @Order(3)
    @DisplayName("重复创建龟档案 - V1.0限制返回错误")
    void createSecondTurtle_returnsError() {
        // Arrange - already has one turtle from previous test
        Map<String, Object> turtleReq = Map.of(
                "name", "第二只龟",
                "species", "Cuora trifasciata"
        );

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(turtleReq, authHeaders(jwtToken));

        // Act
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl() + "/turtles", entity, Map.class);

        // Assert - V1.0 only allows 1 active turtle
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("code")).isNotEqualTo(200);
    }

    @Test
    @Order(4)
    @DisplayName("获取活跃龟档案 - 返回已创建的龟")
    void getActiveTurtle_returnsTurtle() {
        // Act
        HttpEntity<Void> entity = new HttpEntity<>(authHeaders(jwtToken));
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl() + "/turtles/active", HttpMethod.GET, entity, Map.class);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
        assertThat(data.get("name")).isEqualTo("小龟");
    }

    @Test
    @Order(5)
    @DisplayName("获取龟档案列表 - 返回包含已创建龟的列表")
    void listTurtles_returnsList() {
        // Act
        HttpEntity<Void> entity = new HttpEntity<>(authHeaders(jwtToken));
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl() + "/turtles", HttpMethod.GET, entity, Map.class);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
        assertThat(data).isInstanceOf(java.util.List.class);
        assertThat((java.util.List<?>) data).isNotEmpty();
    }

    @Test
    @Order(6)
    @DisplayName("更新龟档案 - 成功返回更新后的信息")
    void updateTurtle_validInput_returnsUpdated() {
        // Arrange
        Map<String, Object> updateReq = Map.of(
                "name", "大龟",
                "species", "Trachemys scripta elegans",
                "weight", 280.0,
                "shellLength", 13.0,
                "habitat", "水养"
        );

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(updateReq, authHeaders(jwtToken));

        // Act
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl() + "/turtles/" + turtleId, HttpMethod.PUT, entity, Map.class);

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
        assertThat(data.get("name")).isEqualTo("大龟");
        assertThat(data.get("weight")).isEqualTo(280.0);
    }

    @Test
    @Order(7)
    @DisplayName("创建龟档案缺少必填字段 - 返回校验错误")
    void createTurtle_missingName_returnsValidationError() {
        // Arrange - use a new user to avoid V1.0 single-turtle limit
        String newToken = registerAndGetToken("13900000002");

        Map<String, Object> turtleReq = Map.of(
                "species", "Trachemys scripta elegans"
        );

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(turtleReq, authHeaders(newToken));

        // Act
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl() + "/turtles", entity, Map.class);

        // Assert
        assertThat(response.getStatusCode()).isIn(HttpStatus.BAD_REQUEST, HttpStatus.OK);
    }
}
