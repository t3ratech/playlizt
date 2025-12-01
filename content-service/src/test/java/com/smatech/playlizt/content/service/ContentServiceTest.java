package com.smatech.playlizt.content.service;

import com.smatech.playlizt.content.dto.ContentRequest;
import com.smatech.playlizt.content.dto.ContentResponse;
import com.smatech.playlizt.content.entity.Content;
import com.smatech.playlizt.content.repository.ContentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ContentServiceTest {

    @Mock
    private ContentRepository contentRepository;

    @Mock
    private AsyncContentEnhancer asyncContentEnhancer;

    @InjectMocks
    private ContentService contentService;

    private Content content;

    @BeforeEach
    void setUp() {
        content = Content.builder()
                .id(1L)
                .title("Test Video")
                .description("Test Description")
                .category("ENTERTAINMENT")
                .videoUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
                .isPublished(true)
                .viewCount(0L)
                .build();
    }

    @Test
    void searchContent_shouldReturnResults() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Content> page = new PageImpl<>(List.of(content));

        when(contentRepository.findAll(any(Specification.class), any(Pageable.class))).thenReturn(page);

        Page<ContentResponse> result = contentService.searchContent("Test", "ENTERTAINMENT", null, null, pageable);

        assertNotNull(result);
        assertEquals(1, result.getContent().size());
        assertEquals("Test Video", result.getContent().get(0).getTitle());
    }

    @Test
    void getAllContent_shouldReturnPublishedContent() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Content> page = new PageImpl<>(List.of(content));
        
        when(contentRepository.findByIsPublishedTrue(pageable)).thenReturn(page);
        
        Page<ContentResponse> result = contentService.getAllContent(pageable);
        
        assertNotNull(result);
        assertEquals(1, result.getContent().size());
    }
    
    @Test
    void createContent_shouldValidateYouTubeUrl() {
        ContentRequest request = new ContentRequest();
        request.setTitle("Invalid Video");
        request.setVideoUrl("https://vimeo.com/123456"); // Invalid
        
        assertThrows(IllegalArgumentException.class, () -> contentService.createContent(request));
    }
    
    @Test
    void createContent_shouldAcceptYouTubeUrl() {
        ContentRequest request = new ContentRequest();
        request.setTitle("Valid Video");
        request.setVideoUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
        request.setCreatorId(1L);
        
        when(contentRepository.save(any(Content.class))).thenReturn(content);
        
        assertDoesNotThrow(() -> contentService.createContent(request));
    }
}
