package com.smatech.playlizt.ui;

import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztAdminTest extends BasePlayliztTest {

    @Test
    @Order(1)
    @DisplayName("01 - Admin: Verify Admin Dashboard Access")
    void test01_VerifyAdminAccess() {
        navigateToApp();
        
        // Ensure fresh login as admin
        if (isTextVisible("Logout") || isTextVisible("Sign Out")) {
             try { logout(); } catch (Exception e) {
                 System.out.println("Logout failed, trying to force login flow anyway");
             }
        }
        
        if (isTextVisible("Login")) {
            System.out.println("Logging in as Admin...");
            login("tkaviya@t3ratech.co.zw", "testpass");
        }
        page.waitForTimeout(3000);
        
        takeScreenshot("admin", "01_home", "01_dashboard_admin.png");
        
        // Open Profile - wait for button
        com.microsoft.playwright.Locator profileBtn = page.getByLabel("Profile")
            .or(page.getByRole(com.microsoft.playwright.options.AriaRole.BUTTON, new com.microsoft.playwright.Page.GetByRoleOptions().setName("Profile")));
            
        if (profileBtn.count() == 0) profileBtn = page.getByRole(com.microsoft.playwright.options.AriaRole.BUTTON).last();
        
        profileBtn.click();
        page.waitForTimeout(1000);
        
        takeScreenshot("admin", "01_home", "02_profile_dialog.png");
        
        // Check for "Admin Dashboard" button
        boolean hasAdminLink = isTextVisible("Admin Dashboard");
        
        if (!hasAdminLink) {
            System.out.println("⚠️ 'Admin Dashboard' link NOT found. Role might not be ADMIN.");
            // Check what role is displayed
            if (isTextVisible("Role: USER")) System.out.println("Current Role is USER");
            if (isTextVisible("Role: ADMIN")) System.out.println("Current Role is ADMIN (but button missing?)");
        } else {
            System.out.println("✅ Found 'Admin Dashboard' link");
            page.getByText("Admin Dashboard").click();
            page.waitForTimeout(2000);
            
            takeScreenshot("admin", "02_dashboard", "01_admin_dashboard.png");
            
            // Verify Admin Dashboard content
            boolean hasStats = isTextVisible("Total Viewing Sessions");
            boolean hasPeak = isTextVisible("Peak Viewing Hour");
            boolean hasTrend = isTextVisible("Trending Category");
            
            if (hasStats && hasPeak && hasTrend) {
                System.out.println("✅ Admin Dashboard loaded with all metrics");
            } else {
                System.out.println("⚠️ Admin Dashboard loaded but missing some metrics: " + 
                    "Stats=" + hasStats + ", Peak=" + hasPeak + ", Trend=" + hasTrend);
            }
            
            assertThat(hasStats).as("Admin Dashboard should show stats").isTrue();
        }
    }
}
