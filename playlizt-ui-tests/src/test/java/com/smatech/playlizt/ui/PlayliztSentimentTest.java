package zw.co.t3ratech.playlizt.ui;

import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztSentimentTest extends BasePlayliztTest {

    @Test
    @Order(1)
    @DisplayName("01 - Sentiment: Verify Metadata Display")
    void test01_VerifySentimentMetadata() {
        navigateToApp();
        
        if (isTextVisible("Login") || isTextVisible("Sign In") || elementExists("input[type='email']")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
        }
        page.waitForTimeout(1500);

        // Ensure the streaming dashboard is ready
        try {
            waitForText("Browse Content", 20000);
        } catch (Exception e) {
            takeScreenshot("failures", "sentiment", "dashboard_not_ready.png");
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("Dashboard not ready due to network/gateway error; environment is not healthy.");
            }
            fail("Dashboard did not become ready (Browse Content not visible): " + e.getMessage());
        }

        // Ensure at least one content card is visible (Flutter web virtualizes)
        boolean contentVisible = false;
        for (int i = 0; i < 60; i++) {
            if (isTextVisible("No content available") || isTextVisible("Error:")) {
                takeScreenshot("failures", "sentiment", "content_load_error.png");
                fail("Content did not load (empty list or error visible). Unable to verify sentiment metadata.");
            }

            if (isTextVisible("views")) {
                contentVisible = true;
                break;
            }

            if (i % 6 == 0) {
                try {
                    page.mouse().wheel(0, 700);
                } catch (Exception ignored) {
                }
            }
            page.waitForTimeout(500);
        }
        if (!contentVisible) {
            takeScreenshot("failures", "sentiment", "no_visible_content.png");
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("No visible content due to network/gateway error; environment is not healthy.");
            }
            fail("No visible content detected on dashboard; unable to verify sentiment metadata.");
        }
        
        takeScreenshot("sentiment", "01_home", "01_dashboard.png");
        
        // Check for Rating text (G, PG, PG-13, R, NC-17)
        // Check for Sentiment text (POSITIVE, NEUTRAL, NEGATIVE, etc.)
        
        boolean hasPG = false;
        boolean hasPG13 = false;
        boolean hasR = false;
        boolean hasG = false;
        boolean hasNC17 = false;

        boolean hasPositive = false;
        boolean hasNeutral = false;
        boolean hasInspiring = false;
        boolean hasEducational = false;
        boolean hasNegative = false;

        // Scroll and retry because Flutter web only exposes semantics for visible widgets
        for (int pass = 0; pass < 8; pass++) {
            hasPG = hasPG || isTextVisible("PG");
            hasPG13 = hasPG13 || isTextVisible("PG-13");
            hasR = hasR || isTextVisible("R");
            hasG = hasG || isTextVisible("G");
            hasNC17 = hasNC17 || isTextVisible("NC-17");

            hasPositive = hasPositive || isTextVisible("POSITIVE");
            hasNeutral = hasNeutral || isTextVisible("NEUTRAL");
            hasInspiring = hasInspiring || isTextVisible("INSPIRING");
            hasEducational = hasEducational || isTextVisible("EDUCATIONAL");
            hasNegative = hasNegative || isTextVisible("NEGATIVE");

            boolean ratingOk = hasG || hasPG || hasPG13 || hasR || hasNC17;
            boolean sentimentOk = hasPositive || hasNeutral || hasInspiring || hasEducational || hasNegative;
            if (ratingOk && sentimentOk) {
                break;
            }

            try {
                page.mouse().wheel(0, 900);
            } catch (Exception ignored) {
            }
            page.waitForTimeout(750);
        }
        
        if (hasG || hasPG || hasPG13 || hasR || hasNC17) {
             System.out.println("✅ Found Content Rating (G/PG/PG-13/R)");
        }
        
        if (hasPositive || hasNeutral || hasInspiring || hasEducational || hasNegative) {
             System.out.println("✅ Found Sentiment (POSITIVE/NEUTRAL/INSPIRING/EDUCATIONAL)");
        }

        if (!((hasG || hasPG || hasPG13 || hasR || hasNC17) || (hasPositive || hasNeutral || hasInspiring || hasEducational || hasNegative))) {
            takeScreenshot("sentiment", "01_home", "02_metadata_missing.png");
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("Sentiment/Rating metadata missing due to network/gateway error; environment is not healthy.");
            }
            fail("Sentiment/Rating metadata not visible on dashboard.");
        }

        takeScreenshot("sentiment", "01_home", "02_metadata_found.png");
        
        assertThat(getCurrentUrl()).doesNotContain("login");
    }
}
