package zw.co.t3ratech.playlizt.auth.security;

import zw.co.t3ratech.playlizt.auth.config.JwtConfig;
import zw.co.t3ratech.playlizt.auth.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JwtUtilTest {

    private JwtUtil jwtUtil;
    private User testUser;
    private String secretKey = "test-secret-key-minimum-32-characters-long-for-hs256-algorithm";
    private long jwtExpiration = 3600000L; // 1 hour
    private long refreshExpiration = 86400000L; // 24 hours
    
    @Mock
    private JwtConfig jwtConfig;

    @BeforeEach
    void setUp() {
        lenient().when(jwtConfig.getSecret()).thenReturn(secretKey);
        lenient().when(jwtConfig.getExpirationMs()).thenReturn(jwtExpiration);
        lenient().when(jwtConfig.getRefreshExpirationMs()).thenReturn(refreshExpiration);
        
        jwtUtil = new JwtUtil(jwtConfig);

        testUser = User.builder()
                .id(1L)
                .username("testuser")
                .email("test@example.com")
                .build();
    }

    @Test
    void shouldGenerateValidAccessToken() {
        String token = jwtUtil.generateToken(testUser);
        
        assertNotNull(token);
        assertFalse(token.isEmpty());
        
        String email = jwtUtil.getEmailFromToken(token);
        assertEquals(testUser.getEmail(), email);
    }

    @Test
    void shouldGenerateValidRefreshToken() {
        String refreshToken = jwtUtil.generateRefreshToken(testUser);
        
        assertNotNull(refreshToken);
        assertFalse(refreshToken.isEmpty());
        
        String email = jwtUtil.getEmailFromToken(refreshToken);
        assertEquals(testUser.getEmail(), email);
    }

    @Test
    void shouldExtractUserIdFromToken() {
        String token = jwtUtil.generateToken(testUser);
        
        Long extractedUserId = jwtUtil.getUserIdFromToken(token);
        assertEquals(testUser.getId(), extractedUserId);
    }

    @Test
    void shouldValidateValidToken() {
        String token = jwtUtil.generateToken(testUser);
        
        boolean isValid = jwtUtil.validateToken(token);
        assertTrue(isValid);
    }

    @Test
    void shouldRejectInvalidToken() {
        String invalidToken = "invalid.token.here";
        
        boolean isValid = jwtUtil.validateToken(invalidToken);
        assertFalse(isValid);
    }

    @Test
    void shouldRejectExpiredToken() {
        // Create a config with very short expiration
        when(jwtConfig.getExpirationMs()).thenReturn(1L); // 1ms
        JwtUtil shortExpiryUtil = new JwtUtil(jwtConfig);
        
        String token = shortExpiryUtil.generateToken(testUser);
        
        // Wait for token to expire
        try {
            Thread.sleep(10);
        } catch (InterruptedException e) {
            fail("Test interrupted");
        }
        
        // Token should be expired
        boolean isValid = shortExpiryUtil.validateToken(token);
        assertFalse(isValid);
    }

    @Test
    void shouldRejectMalformedToken() {
        String malformedToken = "malformed.jwt.token.structure";
        
        boolean isValid = jwtUtil.validateToken(malformedToken);
        assertFalse(isValid);
    }

    @Test
    void shouldHandleTokenWithAllUserInformation() {
        String token = jwtUtil.generateToken(testUser);

        String email = jwtUtil.getEmailFromToken(token);
        Long userId = jwtUtil.getUserIdFromToken(token);

        assertEquals(testUser.getEmail(), email);
        assertEquals(testUser.getId(), userId);
    }

    @Test
    void refreshTokenShouldHaveLongerExpiration() {
        String accessToken = jwtUtil.generateToken(testUser);
        String refreshToken = jwtUtil.generateRefreshToken(testUser);
        
        // Both should be valid
        assertTrue(jwtUtil.validateToken(accessToken));
        assertTrue(jwtUtil.validateToken(refreshToken));
        
        // Extract expiration times using direct JWT parsing
        SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes(StandardCharsets.UTF_8));
        
        Date accessExpiry = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(accessToken)
                .getPayload()
                .getExpiration();
                
        Date refreshExpiry = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(refreshToken)
                .getPayload()
                .getExpiration();
        
        // Refresh token should expire later than access token
        assertTrue(refreshExpiry.after(accessExpiry));
    }
}
