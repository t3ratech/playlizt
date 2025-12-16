package zw.co.t3ratech.playlizt.ui;

import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztAdminTest extends BasePlayliztTest {

    @Test
    @Order(1)
    @DisplayName("01 - Analytics: Verify Platform Analytics Access")
    void test01_VerifyAnalyticsAccess() {
        navigateToApp();

        // Ensure fresh login as a generic user
        if (isTextVisible("Logout") || isTextVisible("Sign Out")) {
            logout();
        }

        if (isTextVisible("Login")) {
            System.out.println("Logging in to view analytics...");
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
        }
        page.waitForTimeout(3000);

        takeScreenshot("analytics", "01_home", "01_dashboard.png");

        // Open Settings drawer instead of legacy Profile dialog
        openSettingsDrawer();
        page.waitForTimeout(1000);

        takeScreenshot("analytics", "01_home", "02_settings_drawer.png");

        // Check for Analytics dashboard button (drawer label uses lowercase 'd')
        boolean hasAnalyticsLink = isTextVisible("Analytics dashboard")
                || isTextVisible("Analytics Dashboard");

        if (!hasAnalyticsLink) {
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("Analytics Dashboard link missing due to network/gateway error; environment is not healthy.");
            }
        }

        assertThat(hasAnalyticsLink).as("Analytics dashboard link should be visible for any authenticated user").isTrue();

        page.getByText("Analytics dashboard")
                .or(page.getByText("Analytics Dashboard"))
                .first()
                .click();
        page.waitForTimeout(2000);

        takeScreenshot("analytics", "02_dashboard", "01_analytics_dashboard.png");

        // Verify Analytics Dashboard content
        boolean hasStats = isTextVisible("Total Viewing Sessions");
        boolean hasPeak = isTextVisible("Peak Viewing Hour");
        boolean hasTrend = isTextVisible("Trending Category");

        assertThat(hasStats).as("Analytics Dashboard should show stats").isTrue();
        assertThat(hasPeak).as("Analytics Dashboard should show peak viewing hour").isTrue();
        assertThat(hasTrend).as("Analytics Dashboard should show trending category").isTrue();
    }
}
