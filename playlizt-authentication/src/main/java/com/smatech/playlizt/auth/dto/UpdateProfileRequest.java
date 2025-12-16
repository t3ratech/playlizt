/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/27 20:51
 * Email        : tkaviya@t3ratech.co.zw
 */
package zw.co.t3ratech.playlizt.auth.dto;

import jakarta.validation.constraints.Email;
import lombok.Data;

@Data
public class UpdateProfileRequest {
    private String username;
    
    @Email
    private String email;
    
    private String password;
}
