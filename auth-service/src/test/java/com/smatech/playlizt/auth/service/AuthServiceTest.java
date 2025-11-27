package com.smatech.playlizt.auth.service;

import com.smatech.playlizt.auth.dto.AuthResponse;
import com.smatech.playlizt.auth.dto.LoginRequest;
import com.smatech.playlizt.auth.dto.RegisterRequest;
import com.smatech.playlizt.auth.entity.User;
import com.smatech.playlizt.auth.repository.UserRepository;
import com.smatech.playlizt.auth.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private AuthService authService;

    private RegisterRequest registerRequest;
    private LoginRequest loginRequest;
    private User user;

    @BeforeEach
    void setUp() {
        registerRequest = RegisterRequest.builder()
                .username("testuser")
                .email("test@example.com")
                .password("Test@123")
                .role(User.UserRole.USER)
                .build();

        loginRequest = LoginRequest.builder()
                .email("test@example.com")
                .password("Test@123")
                .build();

        user = User.builder()
                .id(1L)
                .username("testuser")
                .email("test@example.com")
                .passwordHash("hashedPassword")
                .role(User.UserRole.USER)
                .isActive(true)
                .build();
    }

    @Test
    void shouldRegisterNewUser() {
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(userRepository.existsByUsername(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hashedPassword");
        when(userRepository.save(any(User.class))).thenReturn(user);
        when(jwtUtil.generateToken(any(User.class))).thenReturn("token");
        when(jwtUtil.generateRefreshToken(any(User.class))).thenReturn("refreshToken");

        AuthResponse response = authService.register(registerRequest);

        assertNotNull(response);
        assertEquals(user.getEmail(), response.getEmail());
        assertEquals(user.getUsername(), response.getUsername());
        assertNotNull(response.getToken());
        verify(userRepository, times(1)).save(any(User.class));
    }

    @Test
    void shouldThrowExceptionWhenEmailAlreadyExists() {
        when(userRepository.existsByEmail(anyString())).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> authService.register(registerRequest));
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void shouldAuthenticateValidUser() {
        when(userRepository.findByUsernameOrEmail(anyString(), anyString())).thenReturn(Optional.of(user));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(true);
        when(jwtUtil.generateToken(any(User.class))).thenReturn("token");
        when(jwtUtil.generateRefreshToken(any(User.class))).thenReturn("refreshToken");

        AuthResponse response = authService.login(loginRequest);

        assertNotNull(response);
        assertEquals(user.getEmail(), response.getEmail());
        assertNotNull(response.getToken());
    }

    @Test
    void shouldThrowExceptionForInvalidCredentials() {
        when(userRepository.findByUsernameOrEmail(anyString(), anyString())).thenReturn(Optional.of(user));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(false);

        assertThrows(IllegalArgumentException.class, () -> authService.login(loginRequest));
    }
}
