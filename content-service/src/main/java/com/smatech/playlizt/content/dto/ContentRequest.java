package com.smatech.playlizt.content.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContentRequest {

    @NotNull(message = "Creator ID is required")
    private Long creatorId;

    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title must not exceed 255 characters")
    private String title;

    @Size(max = 5000, message = "Description must not exceed 5000 characters")
    private String description;

    @NotBlank(message = "Category is required")
    private String category;

    private String[] tags;

    private String thumbnailUrl;

    private String videoUrl;

    private Integer durationSeconds;

    private Boolean enhanceWithAi = true;
}
