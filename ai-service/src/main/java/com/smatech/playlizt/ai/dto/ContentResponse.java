package com.smatech.playlizt.ai.dto;

import lombok.Data;

@Data
public class ContentResponse {
    private Long id;
    private String title;
    private String category;
    private String[] tags;
}
