package com.smatech.playlizt.content;

import com.smatech.playlizt.content.dto.ContentRequest;
import com.smatech.playlizt.content.dto.ContentResponse;
import com.smatech.playlizt.content.entity.Content;
import com.smatech.playlizt.content.repository.ContentRepository;
import com.smatech.playlizt.content.service.ContentService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Testcontainers
public class ContentServiceIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:17")
            .withDatabaseName("playlizt_test")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        // Disable Eureka for tests
        registry.add("eureka.client.enabled", () -> "false");
        registry.add("spring.cloud.gcp.sql.enabled", () -> "false");
    }

    @Autowired
    private ContentService contentService;

    @Autowired
    private ContentRepository contentRepository;

    @BeforeEach
    void setUp() {
        contentRepository.deleteAll();
    }

    @Test
    void shouldCreateAndRetrieveContent() {
        ContentRequest request = ContentRequest.builder()
                .title("Integration Test Video")
                .description("Testing with Testcontainers")
                .category("TEST")
                .creatorId(1L)
                .videoUrl("https://www.youtube.com/watch?v=lwxPKgEC1Io")
                .tags(List.of("test", "integration"))
                .build();

        ContentResponse created = contentService.createContent(request);

        assertThat(created.getId()).isNotNull();
        assertThat(created.getTitle()).isEqualTo("Integration Test Video");

        ContentResponse retrieved = contentService.getContent(created.getId());
        assertThat(retrieved).usingRecursiveComparison().isEqualTo(created);
    }

    @Test
    void shouldUpdateContent() {
        // Create
        ContentRequest createRequest = ContentRequest.builder()
                .title("Original Title")
                .description("Original Description")
                .category("TEST")
                .creatorId(1L)
                .tags(List.of("original"))
                .build();
        ContentResponse created = contentService.createContent(createRequest);

        // Update
        ContentRequest updateRequest = ContentRequest.builder()
                .title("Updated Title")
                .description("Updated Description")
                .category("TEST")
                .creatorId(1L)
                .tags(List.of("updated"))
                .build();

        ContentResponse updated = contentService.updateContent(created.getId(), updateRequest);

        assertThat(updated.getTitle()).isEqualTo("Updated Title");
        assertThat(updated.getDescription()).isEqualTo("Updated Description");

        Content saved = contentRepository.findById(created.getId()).orElseThrow();
        assertThat(saved.getTitle()).isEqualTo("Updated Title");
    }

    @Test
    void shouldDeleteContent() {
        ContentRequest request = ContentRequest.builder()
                .title("To Delete")
                .category("TEST")
                .creatorId(1L)
                .tags(List.of("delete"))
                .build();
        ContentResponse created = contentService.createContent(request);

        contentService.deleteContent(created.getId());

        assertThat(contentRepository.findById(created.getId())).isEmpty();
    }
}
