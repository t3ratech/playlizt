package com.smatech.playlizt.auth.dto;

import com.smatech.playlizt.auth.entity.User.UserRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    private Long userId;
    private String username;
    private String email;
    private UserRole role;
    private String token;
    private String refreshToken;
    private Long expiresIn;
}
