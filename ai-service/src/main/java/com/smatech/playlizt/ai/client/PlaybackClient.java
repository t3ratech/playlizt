package com.smatech.playlizt.ai.client;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@FeignClient(name = "playback-service", path = "/api/v1/playback")
public interface PlaybackClient {
    @GetMapping("/history")
    JsonNode getViewingHistory(@RequestParam("userId") Long userId);
}
