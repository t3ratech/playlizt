package com.smatech.playlizt.auth.dto;

import jakarta.validation.constraints.Email;
import lombok.Data;

@Data
public class UpdateProfileRequest {
    private String username;
    
    @Email
    private String email;
    
    private String password;
}
