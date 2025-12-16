/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/27 20:51
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.ai.client;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@FeignClient(name = "playlizt-content-api", path = "/api/v1/content")
public interface ContentClient {
    @GetMapping("/search")
    JsonNode searchContent(
            @RequestParam("q") String query,
            @RequestParam("category") String category,
            @RequestParam("size") int size);
            
    @GetMapping("/categories")
    List<String> getCategories();
}
