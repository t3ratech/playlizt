package com.smatech.playlizt.ai.controller;

import com.smatech.playlizt.ai.dto.ContentResponse;
import com.smatech.playlizt.ai.service.RecommendationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ai")
@RequiredArgsConstructor
@Tag(name = "AI Recommendations", description = "AI-powered recommendation endpoints")
public class RecommendationController {

    private final RecommendationService recommendationService;

    @GetMapping("/recommendations")
    @Operation(summary = "Get recommendations", description = "Get personalized content recommendations")
    public ResponseEntity<List<ContentResponse>> getRecommendations(@RequestParam Long userId) {
        return ResponseEntity.ok(recommendationService.getRecommendations(userId));
    }
}
