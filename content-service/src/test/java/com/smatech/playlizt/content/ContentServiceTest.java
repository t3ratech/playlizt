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

import java.util.Arrays;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ContentServiceTest {

    @Mock
    private ContentRepository contentRepository;

    @Mock
    private GeminiAiService aiService;

    @InjectMocks
    private ContentService contentService;

    private Content testContent;
    private ContentRequest testRequest;

    @BeforeEach
    void setUp() {
        testContent = Content.builder()
                .id(1L)
                .creatorId(100L)
                .title("Test Video")
                .description("Test Description")
                .videoUrl("https://test.com/video.mp4")
                .category("ACTION")
                .isPublished(true)
                .viewCount(0L)
                .build();

        testRequest = ContentRequest.builder()
                .title("New Video")
                .description("New Description")
                .videoUrl("https://test.com/new.mp4")
                .category("ACTION")
                .build();
    }

    @Test
    void shouldCreateContent() {
        when(contentRepository.save(any(Content.class))).thenReturn(testContent);

        ContentResponse response = contentService.createContent(testRequest);

        assertNotNull(response);
        verify(contentRepository, times(1)).save(any(Content.class));
    }

    @Test
    void shouldGetContent() {
        when(contentRepository.findById(1L)).thenReturn(Optional.of(testContent));

        ContentResponse response = contentService.getContent(1L);

        assertNotNull(response);
        assertEquals(1L, response.getId());
    }

    @Test
    void shouldGetAllContent() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Content> contentPage = new PageImpl<>(Arrays.asList(testContent));
        when(contentRepository.findByIsPublishedTrue(pageable)).thenReturn(contentPage);

        Page<ContentResponse> result = contentService.getAllContent(pageable);

        assertNotNull(result);
        assertEquals(1, result.getTotalElements());
    }

    @Test
    void shouldUpdateContent() {
        when(contentRepository.findById(1L)).thenReturn(Optional.of(testContent));
        when(contentRepository.save(any(Content.class))).thenReturn(testContent);

        ContentResponse response = contentService.updateContent(1L, testRequest);

        assertNotNull(response);
        verify(contentRepository, times(1)).save(any(Content.class));
    }

    @Test
    void shouldDeleteContent() {
        doNothing().when(contentRepository).deleteById(1L);

        contentService.deleteContent(1L);

        verify(contentRepository, times(1)).deleteById(1L);
    }

    @Test
    void shouldPublishContent() {
        when(contentRepository.findById(1L)).thenReturn(Optional.of(testContent));
        when(contentRepository.save(any(Content.class))).thenReturn(testContent);

        contentService.publishContent(1L);

        verify(contentRepository, times(1)).save(any(Content.class));
    }
}
