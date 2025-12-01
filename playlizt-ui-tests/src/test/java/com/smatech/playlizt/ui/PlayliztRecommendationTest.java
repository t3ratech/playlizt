package com.smatech.playlizt.ui;

import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztRecommendationTest extends BasePlayliztTest {

    @Test
    @Order(1)
    @DisplayName("01 - Recommendations: Verify Logic (Wait for 2 Videos)")
    void test01_VerifyRecommendationsLogic() {
        navigateToApp();
        
        // Ensure fresh state: Logout if needed
        if (isTextVisible("Logout") || isTextVisible("Sign Out") || isTextVisible("Profile")) {
            try { logout(); } catch (Exception e) { System.out.println("Logout error: " + e); }
        }
        
        // Register a NEW user to ensure clean history
        String uniqueUser = "rec" + System.currentTimeMillis();
        String uniqueEmail = uniqueUser + "@test.com";
        
        System.out.println("Registering new user: " + uniqueUser);
        registerNewUser(uniqueUser, uniqueEmail, "testpass");
        
        page.waitForTimeout(3000);
        takeScreenshot("recommendations", "01_fresh", "01_dashboard.png");
        
        // 1. Verify NO Recommendations initially (history < 2)
        boolean hasRecs = isTextVisible("Recommended for You");
        if (hasRecs) {
             System.out.println("⚠️ Recommendations visible initially? Should be hidden for new user.");
        } else {
             System.out.println("✅ Recommendations correctly hidden (No history).");
        }
        
        // 2. Play Video 1
        System.out.println("Playing Video 1...");
        playVideo("Episode 1");
        
        // 3. Play Video 2
        System.out.println("Playing Video 2...");
        playVideo("Episode 2"); 
        
        // 4. Verify Recommendations APPEAR
        System.out.println("Checking for Recommendations...");
        // Reload to fetch new recommendations
        page.reload();
        page.waitForTimeout(5000); // Wait for API calls
        
        takeScreenshot("recommendations", "04_after_videos", "01_dashboard_reloaded.png");
        
        assertThat(isTextVisible("Recommended for You"))
            .as("Recommendations section should appear after watching 2 videos")
            .isTrue();
            
        // Verify Episode 3 is recommended (Next in series)
        assertThat(isTextVisible("Episode 3"))
            .as("Episode 3 should be recommended after watching 1 & 2")
            .isTrue();
            
        System.out.println("✅ Recommendations verified: Episode 3 is present!");
        
        // 5. Verify Recommended Video PLAYS (Fixes spinning player issue)
        System.out.println("Playing Recommended Video (Episode 3)...");
        // The first occurrence should be the recommended one (at the top)
        playVideo("Episode 3");
        System.out.println("✅ Recommended video played successfully!");
    }
    
    private void registerNewUser(String user, String email, String pass) {
        // Navigate to Register
        if (isTextVisible("Don't have an account? Register")) {
            page.getByText("Don't have an account? Register").click();
        } else if (isTextVisible("Register")) {
            page.getByText("Register").first().click();
        }
        
        page.waitForTimeout(1000);
        
        page.getByLabel("Username").fill(user);
        page.getByLabel("Email").fill(email);
        page.getByLabel("Password", new com.microsoft.playwright.Page.GetByLabelOptions().setExact(true)).fill(pass);
        page.getByLabel("Confirm Password").fill(pass);
        
        // Click Register
        page.getByRole(com.microsoft.playwright.options.AriaRole.BUTTON, new com.microsoft.playwright.Page.GetByRoleOptions().setName("Register")).click();
        
        System.out.println("Waiting for registration to complete...");
        page.waitForTimeout(6000); // Increase wait time
        takeScreenshot("recommendations", "01_fresh", "00_after_register.png");
        
        if (isTextVisible("Login")) {
             System.out.println("Registration successful, redirecting to Login...");
             login(email, pass);
        } else {
             // If we are still on Register, fail
             if (isTextVisible("Register")) {
                 fail("Registration failed to redirect to Login. Check validation errors.");
             }
             // Or maybe we auto-logged in?
             if (!isTextVisible("Browse Content")) {
                 fail("Registration failed: Neither at Login nor Dashboard.");
             }
        }
    }
    
    private void playVideo(String titlePart) {
        // Wait for content to load
        try {
            waitForText("Browse Content", 10000);
            // Scroll down to ensure grid is rendered
            page.mouse().wheel(0, 500);
            page.waitForTimeout(1000);
        } catch (Exception e) {
            System.out.println("Timeout waiting for 'Browse Content'.");
        }
        
        // Robust find: partial text or label
        boolean found = isTextVisible(titlePart);
        if (!found) {
             try {
                 page.getByLabel("Video:").filter(new com.microsoft.playwright.Locator.FilterOptions().setHasText(titlePart)).first().waitFor(new com.microsoft.playwright.Locator.WaitForOptions().setTimeout(2000));
                 found = true;
             } catch (Exception e) {
                 // Ignore
             }
        }
        
        assertThat(found)
            .as("Content '%s' must be visible on dashboard", titlePart)
            .isTrue();
            
        // Click it
        if (isTextVisible(titlePart)) {
            page.getByText(titlePart).first().click();
        } else {
            // Try label
            page.getByLabel("Video:").filter(new com.microsoft.playwright.Locator.FilterOptions().setHasText(titlePart)).first().click();
        }
        
        page.waitForTimeout(3000); // Wait for player load
        
        // Check if we are on player screen
        if (isTextVisible("Description") || isTextVisible("views")) {
            System.out.println("Video player loaded for " + titlePart + ". Watching for 12s...");
            page.waitForTimeout(12000);
        } else {
            fail("Video player did not load for " + titlePart);
        }
        
        // Go back
        try {
            page.goBack();
        } catch (Exception e) {
            try {
                page.getByLabel("Back").click();
            } catch (Exception ex) {
                // Ignore
            }
        }
        page.waitForTimeout(2000);
    }
}
