package com.smatech.playlizt.auth;

import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;

public class PasswordGeneratorTest {

    @Test
    public void generatePassword() {
        Argon2PasswordEncoder encoder = Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8();
        String hash = encoder.encode("testpass");
        System.out.println("GENERATED_HASH: " + hash);
    }
}
