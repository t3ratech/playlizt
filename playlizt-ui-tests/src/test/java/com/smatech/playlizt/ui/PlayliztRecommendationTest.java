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
        
        // 3b. Play Video 1 AGAIN to reach 3 total views (Threshold is > 2)
        System.out.println("Playing Video 1 again to increment view count...");
        playVideo("Episode 1");
        
        // 4. Verify Recommendations APPEAR
        System.out.println("Checking for Recommendations...");

        // Poll for the recommendations section for up to ~30 seconds. This keeps the
        // test strict (it will fail if they never appear) while allowing for
        // realistic async latency between playback tracking and AI response.
        boolean recSectionVisible = false;
        for (int i = 0; i < 12; i++) { // 12 * 2500ms ≈ 30s max
            recSectionVisible = isTextVisible("Recommended for You");
            if (recSectionVisible) {
                break;
            }

            // If we ever see a clear network/gateway issue while waiting, fail hard.
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("Recommendations section not visible after watching 3 videos due to network/gateway error; environment is not healthy.");
            }

            page.waitForTimeout(2500);
        }

        // Capture the final dashboard state for inspection
        takeScreenshot("recommendations", "04_after_videos", "01_dashboard_reloaded.png");

        if (!recSectionVisible) {
            fail("Recommendations section not visible after watching 3 videos.");
        }

        // Best-effort check for Episode 3 as the next-in-series recommendation.
        boolean episode3Visible = isTextVisible("Episode 3");
        if (!episode3Visible) {
            fail("Episode 3 recommendation not visible after meeting view threshold.");
        }

        // 5. Play Recommended Video (only if we can reliably see it)
        System.out.println("Playing Recommended Video (Episode 3)...");
        playVideo("Episode 3");
        System.out.println("✅ Recommended video played successfully!");
    }
    
    private void registerNewUser(String user, String email, String pass) {
        // Use the shared navigation + registration helper from BasePlayliztTest
        // so this flow matches the main auth tests.
        navigateToRegister();
        register(user, email, pass);

        System.out.println("Waiting for registration to complete...");
        page.waitForTimeout(6000); // Allow Flutter to pop back to Login
        takeScreenshot("recommendations", "01_fresh", "00_after_register.png");

        if (isTextVisible("Login") || isTextVisible("Sign In")) {
            System.out.println("Registration successful, redirecting to Login...");
            login(email, pass);
            return;
        }

        if (isTextVisible("Browse Content")) {
            System.out.println("Registration appears to have auto-logged in; continuing from dashboard.");
            return;
        }

        boolean networkProblem =
                consoleContains("Network error. Please check your connection.") ||
                consoleContains("ERR_CONNECTION_REFUSED");

        if (isTextVisible("Register")) {
            takeScreenshot("recommendations", "01_fresh", "00_register_error.png");
            if (networkProblem) {
                fail("Registration failed to leave Register page due to network/gateway error; environment is not healthy.");
            }
            fail("Registration failed to reach Login or Dashboard after submit. Check validation errors on Register page.");
        } else {
            if (networkProblem) {
                fail("Registration ended in unexpected state due to network/gateway error; environment is not healthy.");
            }
            fail("Registration ended in unexpected state (not Login, Dashboard, or Register).");
        }
    }
    
    private void playVideo(String titlePart) {
        // Ensure we are back on the Home dashboard before trying to play
        try {
            // Always use explicit navigation instead of browser history to avoid target crashes
            navigateToApp();

            // Final wait for the Browse Content section to be visible
            waitForText("Browse Content", 10000);
            // Scroll down to ensure grid is rendered
            page.mouse().wheel(0, 500);
            page.waitForTimeout(1000);
        } catch (Exception e) {
            System.out.println("Timeout waiting for 'Browse Content' after navigateToApp: " + e.getMessage());
        }
        
        // Soft visibility check: try to see the text or a labelled card,
        // but do not fail the test here as Flutter semantics can be flaky.
        boolean found = isTextVisible(titlePart);
        if (!found) {
            try {
                page.getByLabel("Video:")
                    .filter(new com.microsoft.playwright.Locator.FilterOptions().setHasText(titlePart))
                    .first()
                    .waitFor(new com.microsoft.playwright.Locator.WaitForOptions().setTimeout(2000));
                found = true;
            } catch (Exception e) {
                System.out.println("Warning: text/label for '" + titlePart + "' not reliably visible, proceeding to click card anyway.");
            }
        }

        // Click it using robust Flutter-friendly locators
        com.microsoft.playwright.Locator videoCard = null;

        // 1. Try accessible text locator if it exists
        try {
            videoCard = page.getByText(titlePart).first();
            if (videoCard == null || videoCard.count() == 0) {
                videoCard = null;
            }
        } catch (Exception e) {
            videoCard = null;
        }

        // 2. Try aria-label based locator (Flutter Semantics)
        if (videoCard == null || videoCard.count() == 0) {
            try {
                videoCard = page.locator("[aria-label*='" + titlePart + "']").first();
            } catch (Exception e) {
                videoCard = null;
            }
        }

        // 3. Fallback: explicit "Video:" label pattern
        if (videoCard == null || videoCard.count() == 0) {
            try {
                videoCard = page.getByLabel("Video:")
                    .filter(new com.microsoft.playwright.Locator.FilterOptions().setHasText(titlePart))
                    .first();
            } catch (Exception e) {
                videoCard = null;
            }
        }

        if (videoCard == null || videoCard.count() == 0) {
            takeScreenshot("recommendations", "01_fresh", "00_missing_video_" + titlePart.replaceAll("\\s+", "_") + ".png");
            fail("Unable to locate clickable card for '" + titlePart + "'");
        }

        try {
            videoCard.scrollIntoViewIfNeeded();
            videoCard.click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
        } catch (Exception e) {
            System.out.println("Standard click failed for '" + titlePart + "', trying JS click: " + e.getMessage());
            try {
                videoCard.evaluate("node => node.click()");
            } catch (Exception ex) {
                takeScreenshot("recommendations", "01_fresh", "00_click_failed_" + titlePart.replaceAll("\\s+", "_") + ".png");
                fail("Failed to click video card for '" + titlePart + "': " + ex.getMessage());
            }
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
            System.out.println("Returning to dashboard after playing " + titlePart + "...");

            // Always use explicit navigation to the app root instead of relying on
            // in-app Back buttons or browser history. This ensures that after heavy
            // video playback (especially YouTube iframes) we fully reload the
            // Flutter app and avoid being left on Chrome's crash page.
            navigateToApp();

            // Wait for dashboard marker, but do not fail hard if it is not strictly visible
            try {
                waitForText("Browse Content", 10000);
            } catch (Exception e) {
                System.out.println("Warning: 'Browse Content' not detected after returning from player: " + e.getMessage());
            }
        } catch (Exception e) {
            System.out.println("Error returning to dashboard after video: " + e.getMessage());
            try {
                navigateToApp();
            } catch (Exception ex) {
                System.out.println("Fallback navigateToApp after error also failed: " + ex.getMessage());
            }
        }
        page.waitForTimeout(2000);
    }
}
