package com.smatech.playlizt.ai.client;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@FeignClient(name = "content-service", path = "/api/v1/content")
public interface ContentClient {
    @GetMapping("/search")
    JsonNode searchContent(
            @RequestParam("q") String query,
            @RequestParam("category") String category,
            @RequestParam("size") int size);
            
    @GetMapping("/categories")
    List<String> getCategories();
}
