package com.smatech.playlizt.ai.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(InsightsController.class)
@TestPropertySource(properties = {
    "server.port=8085",
    "SERVER_PORT=8085",
    "EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://localhost:8761/eureka",
    "GEMINI_API_KEY=dummy"
})
class InsightsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void getInsights_shouldReturnMockData() throws Exception {
        mockMvc.perform(get("/api/v1/ai/insights"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.trending_themes").isArray())
                .andExpect(jsonPath("$.peak_usage_time").exists());
    }
}
