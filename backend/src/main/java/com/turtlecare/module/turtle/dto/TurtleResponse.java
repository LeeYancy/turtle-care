package com.turtlecare.module.turtle.dto;

import com.turtlecare.module.turtle.model.Turtle;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class TurtleResponse {
    private Long id;
    private String name;
    private String species;
    private String speciesCn;
    private String gender;
    private Double weight;
    private Double shellLength;
    private LocalDate birthDate;
    private String photoUrl;
    private String habitat;
    private String notes;
    private LocalDateTime createdAt;

    // 最新健康记录摘要（查询活跃龟时附带）
    private String latestHealthRisk;
    private String latestHealthSummary;

    public static TurtleResponse from(Turtle t) {
        return TurtleResponse.builder()
                .id(t.getId())
                .name(t.getName())
                .species(t.getSpecies())
                .speciesCn(t.getSpeciesCn())
                .gender(t.getGender())
                .weight(t.getWeight())
                .shellLength(t.getShellLength())
                .birthDate(t.getBirthDate())
                .photoUrl(t.getPhotoUrl())
                .habitat(t.getHabitat())
                .notes(t.getNotes())
                .createdAt(t.getCreatedAt())
                .build();
    }
}
