/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/27 20:51
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.ai.controller;

import zw.co.t3ratech.playlizt.ai.dto.ContentResponse;
import zw.co.t3ratech.playlizt.ai.service.RecommendationService;
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
