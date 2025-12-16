package zw.co.t3ratech.playlizt.ui;

import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztRecommendationTest extends BasePlayliztTest {

    @Test
    @Order(1)
    @DisplayName("01 - Recommendations: Verify Logic (Wait for 2 Videos)")
    void test01_VerifyRecommendationsLogic() {
        navigateToApp();

        // Use the seeded test user credentials from test.properties.
        // BasePlayliztTest resets to Login before each test, so we must log in here.
        if (isTextVisible("Login") || isTextVisible("Sign In")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
            page.waitForTimeout(2000);
        }

        takeScreenshot("recommendations", "01_seeded_user", "01_dashboard.png");
        
        // 2. Play Video 1
        System.out.println("Playing Video 1...");
        playVideo("Episode 1");
        
        // 3. Play Video 2
        System.out.println("Playing Video 2...");
        playVideo("Episode 2"); 

        // 4. Verify Recommendations APPEAR
        System.out.println("Checking for Recommendations...");

        // Poll for the recommendations section for up to ~30 seconds. This keeps the
        // test strict (it will fail if they never appear) while allowing for
        // realistic async latency between playback tracking and AI response.
        // Ensure we're on the dashboard again after video playback.
        navigateToApp();
        if (isTextVisible("Login") || isTextVisible("Sign In")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
            page.waitForTimeout(2000);
        }

        boolean recSectionVisible = false;
        for (int i = 0; i < 10; i++) { // 10 * 2000ms = 20s max
            recSectionVisible = isTextVisible("Recommended for You");
            if (recSectionVisible) {
                break;
            }

            // If we ever see a clear network/gateway issue while waiting, fail hard.
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("Recommendations section not visible due to network/gateway error; environment is not healthy.");
            }

            page.reload();
            page.waitForTimeout(2000);
        }

        // Capture the final dashboard state for inspection
        takeScreenshot("recommendations", "04_after_videos", "01_dashboard_reloaded.png");

        if (!recSectionVisible) {
            fail("Recommendations section not visible after watching 2 distinct videos; expected it to appear after meeting threshold.");
        }

        // STRICT: Expect Episode 3 to be recommended after watching Episodes 1 and 2.
        if (!isTextVisible("Episode 3")) {
            takeScreenshot("recommendations", "04_after_videos", "02_missing_episode_3.png");
            fail("Episode 3 recommendation not visible after meeting view threshold.");
        }
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
        navigateToApp();
        if (isTextVisible("Login") || isTextVisible("Sign In")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
            page.waitForTimeout(2000);
        }

        try {
            waitForText("Browse Content", 10000);
        } catch (Exception e) {
            takeScreenshot("recommendations", "02_play", "00_missing_dashboard.png");
            fail("Dashboard did not become ready before playing '" + titlePart + "': " + e.getMessage());
        }

        // Scroll down to ensure the grid is rendered
        page.mouse().wheel(0, 500);
        page.waitForTimeout(750);

        com.microsoft.playwright.Locator videoCard = findVideoCardByTitlePart(titlePart);
        if (videoCard == null) {
            takeScreenshot("recommendations", "02_play", "01_missing_video_" + titlePart.replaceAll("\\s+", "_") + ".png");
            fail("Unable to locate clickable card for '" + titlePart + "'");
        }

        try {
            videoCard.scrollIntoViewIfNeeded();
        } catch (Exception ignored) {
        }
        videoCard.click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));

        // Wait for player screen marker
        try {
            // Either Description text or views counter is present on the player page
            for (int i = 0; i < 20; i++) {
                if (isTextVisible("Description") || isTextVisible("views")) {
                    break;
                }
                page.waitForTimeout(250);
            }
        } catch (Exception ignored) {
        }

        if (!(isTextVisible("Description") || isTextVisible("views"))) {
            takeScreenshot("recommendations", "02_play", "02_player_not_loaded_" + titlePart.replaceAll("\\s+", "_") + ".png");
            fail("Video player did not load for " + titlePart);
        }

        // Keep this short: we only need the tracking call to be emitted.
        page.waitForTimeout(2000);

        // Return to dashboard
        navigateToApp();
        page.waitForTimeout(1000);
    }

    private com.microsoft.playwright.Locator findVideoCardByTitlePart(String titlePart) {
        // 1) Preferred if semantics are present
        try {
            com.microsoft.playwright.Locator byAria = page.locator(
                    "[aria-label^='Video:'][aria-label*='" + titlePart + "']"
            ).first();

            if (byAria.count() > 0) {
                try {
                    byAria.waitFor(new com.microsoft.playwright.Locator.WaitForOptions().setTimeout(2500));
                } catch (Exception ignored) {
                }
                if (byAria.isVisible()) {
                    return byAria;
                }
            }
        } catch (Exception ignored) {
        }

        // 2) Fallback: click by visible title text (works with current UI, e.g. "Tha Streetz TV - Episode 1")
        try {
            com.microsoft.playwright.Locator byText = page.getByText(titlePart).first();
            if (byText.count() > 0) {
                try {
                    byText.waitFor(new com.microsoft.playwright.Locator.WaitForOptions().setTimeout(4000));
                } catch (Exception ignored) {
                }
                if (byText.isVisible()) {
                    return byText;
                }
            }
        } catch (Exception ignored) {
        }

        return null;
    }
}
