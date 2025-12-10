package com.smatech.playlizt.ui;

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
             try { logout(); } catch (Exception e) {
                 System.out.println("Logout failed, trying to force login flow anyway");
             }
        }

        if (isTextVisible("Login")) {
            System.out.println("Logging in to view analytics...");
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
        }
        page.waitForTimeout(3000);

        takeScreenshot("analytics", "01_home", "01_dashboard.png");

        // Open Profile - wait for button
        com.microsoft.playwright.Locator profileBtn = page.getByLabel("Profile")
            .or(page.getByRole(com.microsoft.playwright.options.AriaRole.BUTTON, new com.microsoft.playwright.Page.GetByRoleOptions().setName("Profile")));

        if (profileBtn.count() == 0) profileBtn = page.getByRole(com.microsoft.playwright.options.AriaRole.BUTTON).last();

        profileBtn.click();
        page.waitForTimeout(1000);

        takeScreenshot("analytics", "01_home", "02_profile_dialog.png");

        // Check for Analytics Dashboard button
        boolean hasAnalyticsLink = isTextVisible("Analytics Dashboard");

        if (!hasAnalyticsLink) {
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("Analytics Dashboard link missing due to network/gateway error; environment is not healthy.");
            }
        }

        assertThat(hasAnalyticsLink).as("Analytics Dashboard link should be visible for any authenticated user").isTrue();

        page.getByText("Analytics Dashboard").click();
        page.waitForTimeout(2000);

        takeScreenshot("analytics", "02_dashboard", "01_analytics_dashboard.png");

        // Verify Analytics Dashboard content
        boolean hasStats = isTextVisible("Total Viewing Sessions");
        boolean hasPeak = isTextVisible("Peak Viewing Hour");
        boolean hasTrend = isTextVisible("Trending Category");

        if (hasStats && hasPeak && hasTrend) {
            System.out.println("✅ Analytics Dashboard loaded with all metrics");
        } else {
            System.out.println("⚠️ Analytics Dashboard loaded but missing some metrics: " +
                "Stats=" + hasStats + ", Peak=" + hasPeak + ", Trend=" + hasTrend);
        }

        assertThat(hasStats).as("Analytics Dashboard should show stats").isTrue();
    }
}
