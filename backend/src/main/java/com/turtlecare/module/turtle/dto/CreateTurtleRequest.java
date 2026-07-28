package com.turtlecare.module.turtle.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateTurtleRequest {
    @NotBlank(message = "龟的名字不能为空")
    private String name;

    @NotBlank(message = "请选择龟的品种")
    private String species;

    private String gender;
    private Double weight;
    private Double shellLength;
    private String birthDate;
    private String habitat;
    private String notes;
}
