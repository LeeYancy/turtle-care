package com.turtlecare.common.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.Components;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * OpenAPI / Swagger documentation configuration.
 * Access at: /swagger-ui.html
 * API docs at: /v3/api-docs
 */
@Configuration
public class OpenAPIConfig {

    private static final String SECURITY_SCHEME_NAME = "Bearer Authentication";

    @Bean
    public OpenAPI turtleCareOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("TurtleCare API")
                        .description("AI智能养龟管家 - REST API 文档\n\n" +
                                "所有需认证的接口请在右上角 Authorize 中输入 JWT Token。\n\n" +
                                "Token 格式: `Bearer <your-jwt-token>`")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("TurtleCare Team")
                                .email("dev@turtlecare.com"))
                        .license(new License()
                                .name("MIT License")
                                .url("https://opensource.org/licenses/MIT")))
                .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME_NAME))
                .components(new Components()
                        .addSecuritySchemes(SECURITY_SCHEME_NAME, new SecurityScheme()
                                .name(SECURITY_SCHEME_NAME)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("输入 JWT Token 进行认证")));
    }
}
