/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/26 12:59
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.auth.service;

import zw.co.t3ratech.playlizt.auth.dto.AuthResponse;
import zw.co.t3ratech.playlizt.auth.dto.LoginRequest;
import zw.co.t3ratech.playlizt.auth.dto.RegisterRequest;
import zw.co.t3ratech.playlizt.auth.dto.UpdateProfileRequest;
import zw.co.t3ratech.playlizt.auth.dto.UserSettingsDto;
import zw.co.t3ratech.playlizt.auth.entity.PlayliztUserSettings;
import zw.co.t3ratech.playlizt.auth.entity.User;
import zw.co.t3ratech.playlizt.auth.model.PlayliztTab;
import zw.co.t3ratech.playlizt.auth.model.PlayliztTheme;
import zw.co.t3ratech.playlizt.auth.repository.PlayliztUserSettingsRepository;
import zw.co.t3ratech.playlizt.auth.repository.UserRepository;
import zw.co.t3ratech.playlizt.auth.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final PlayliztUserSettingsRepository userSettingsRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthResponse createGuestSession() {
        String guestToken = jwtUtil.generateGuestToken();
        // Return minimal response with token; no user ID/username/email for guest
        return AuthResponse.builder()
                .token(guestToken)
                .expiresIn(3600000L)
                // Use defaults for settings, but mapped to DTO
                .settings(
                        UserSettingsDto.builder()
                                .theme(PlayliztTheme.DARK)
                                .startupTab(PlayliztTab.STREAMING)
                                .visibleTabs(defaultVisibleTabs())
                                .downloadDirectory("~/Downloads")
                                .libraryScanFolders(new ArrayList<>())
                                .maxConcurrentDownloads(2)
                                .build()
                )
                .build();
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        log.info("Registering new user: {}", request.getEmail());

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already registered");
        }

        if (userRepository.existsByUsername(request.getUsername())) {
            throw new IllegalArgumentException("Username already taken");
        }

        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .isActive(true)
                .build();

        user = userRepository.save(user);
        log.info("User registered successfully: {}", user.getEmail());

        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        log.info("Login attempt for: {}", request.getEmail());

        String identifier = request.getEmail();
        User user = userRepository.findByUsernameOrEmail(identifier, identifier)
                .filter(User::getIsActive)
                .orElseThrow(() -> new IllegalArgumentException("Invalid credentials"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid credentials");
        }

        user.setLastLogin(LocalDateTime.now());
        userRepository.save(user);

        log.info("User logged in successfully: {}", user.getEmail());
        return buildAuthResponse(user);
    }

    public AuthResponse refreshToken(String refreshToken) {
        if (!jwtUtil.validateToken(refreshToken)) {
            throw new IllegalArgumentException("Invalid refresh token");
        }

        String email = jwtUtil.getEmailFromToken(refreshToken);
        User user = userRepository.findActiveByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse updateProfile(String token, UpdateProfileRequest request) {
        if (!jwtUtil.validateToken(token)) {
            throw new IllegalArgumentException("Invalid token");
        }
        String email = jwtUtil.getEmailFromToken(token);

        User user = userRepository.findActiveByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (request.getUsername() != null && !request.getUsername().isEmpty()) {
            user.setUsername(request.getUsername());
        }
        if (request.getEmail() != null && !request.getEmail().isEmpty()) {
            user.setEmail(request.getEmail());
        }
        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        }

        user = userRepository.save(user);
        return buildAuthResponse(user);
    }

    private AuthResponse buildAuthResponse(User user) {
        String token = jwtUtil.generateToken(user);
        String refreshToken = jwtUtil.generateRefreshToken(user);

        PlayliztUserSettings settings = loadOrCreateSettings(user);
        UserSettingsDto settingsDto = UserSettingsDto.builder()
                .theme(settings.getTheme())
                .startupTab(settings.getStartupTab())
                .visibleTabs(new ArrayList<>(settings.getVisibleTabs()))
                .downloadDirectory(settings.getDownloadDirectory())
                .libraryScanFolders(new ArrayList<>(settings.getLibraryScanFolders()))
                .maxConcurrentDownloads(settings.getMaxConcurrentDownloads())
                .build();

        return AuthResponse.builder()
                .userId(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .token(token)
                .refreshToken(refreshToken)
                .expiresIn(3600000L) // 1 hour in milliseconds
                .settings(settingsDto)
                .build();
    }

    private PlayliztUserSettings loadOrCreateSettings(User user) {
        return userSettingsRepository.findByUser(user)
                .orElseGet(() -> {
                    PlayliztUserSettings defaults = PlayliztUserSettings.builder()
                            .user(user)
                            .theme(PlayliztTheme.DARK)
                            .startupTab(PlayliztTab.STREAMING)
                            .visibleTabs(defaultVisibleTabs())
                            .downloadDirectory("~/Downloads")
                            .libraryScanFolders(new ArrayList<>())
                            .maxConcurrentDownloads(2)
                            .build();
                    return userSettingsRepository.save(defaults);
                });
    }

    private List<PlayliztTab> defaultVisibleTabs() {
        // Order: LIBRARY, PLAYLISTS, STREAMING, DOWNLOAD, CONVERT, DEVICES
        List<PlayliztTab> tabs = new ArrayList<>();
        tabs.add(PlayliztTab.LIBRARY);
        tabs.add(PlayliztTab.PLAYLISTS);
        tabs.add(PlayliztTab.STREAMING);
        tabs.add(PlayliztTab.DOWNLOAD);
        tabs.add(PlayliztTab.CONVERT);
        tabs.add(PlayliztTab.DEVICES);
        return tabs;
    }
}
