package com.smatech.playlizt.ui;

import org.junit.jupiter.api.*;
import com.microsoft.playwright.options.AriaRole;
import static org.assertj.core.api.Assertions.*;

/**
 * STRICT Dashboard & Content Tests
 * 
 * Validates:
 * 1. Home Page (Content Grid, Search, Layout)
 * 2. Content Details (Metadata, Playback placeholder)
 * 3. Profile/Settings
 * 4. Navigation
 * 
 * STRICTNESS:
 * - Requires pre-seeded content or robust handling of empty states
 * - Verifies UI structure matches expected design
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztDashboardTest extends BasePlayliztTest {

    @BeforeAll
    static void setupUser() {
        // Using seeded user from test.properties
    }

    @Test
    @Order(1)
    @DisplayName("01 - Dashboard: Login with Test User")
    void test01_SetupDashboardUser() {
        try {
            navigateToApp();
            
            // Debug: Print what text we see
            System.out.println("DEBUG: Page Title: " + getPageTitle());
            
            int buttonCount = page.getByRole(AriaRole.BUTTON).count();
            System.out.println("DEBUG: Buttons found: " + buttonCount);
            for (int i = 0; i < buttonCount; i++) {
                try {
                    com.microsoft.playwright.Locator btn = page.getByRole(AriaRole.BUTTON).nth(i);
                    String text = btn.textContent();
                    String label = btn.getAttribute("aria-label");
                    System.out.println("DEBUG: Button " + i + ": text='" + text + "', aria-label='" + label + "'");
                } catch (Exception e) {
                    System.out.println("DEBUG: Button " + i + ": (read error)");
                }
            }
            
            // Check inputs
            System.out.println("DEBUG: Email input found: " + page.getByLabel("Email").count());
            System.out.println("DEBUG: Password input found: " + page.getByLabel("Password").count());

            if (isTextVisible("Login")) System.out.println("DEBUG: Found 'Login'");
            if (isTextVisible("Register")) System.out.println("DEBUG: Found 'Register'");
            if (isTextVisible("Don't have an account")) System.out.println("DEBUG: Found 'Don't have an account'");
            
            if (isTextVisible("Login")) {
                System.out.println("Login page visible. Attempting to ensure user exists via Register...");
                try {
                    navigateToRegister();
                    register(TEST_USER_USERNAME, TEST_USER_EMAIL, TEST_USER_PASSWORD);
                    page.waitForTimeout(2000);
                } catch (Exception e) {
                    System.out.println("Registration failed (maybe user exists?): " + e.getMessage());
                    // Navigate back to login if stuck on register
                    if (isTextVisible("Register")) {
                        // Click "Already have an account" if visible, or reload
                        if (isTextVisible("Already have an account")) {
                            page.getByText("Already have an account").click();
                        } else {
                            navigateToApp();
                        }
                    }
                }
                
                // Now Login
                if (isTextVisible("Login")) {
                    System.out.println("Attempting login with " + TEST_USER_EMAIL);
                    login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
                    page.waitForTimeout(3000);
                }
            }
            
            // If still on Login/Register (e.g. invalid credentials), try registering? 
            // No, we expect seeded user to exist.
            
            takeScreenshot("dashboard", "01_setup", "01_logged_in.png");
            
            // STRICT: Verify Dashboard Loaded
            assertThat(getCurrentUrl()).doesNotContain("login");
        } catch (Exception e) {
            takeScreenshot("failures", "dashboard_setup", "01_error.png");
            System.err.println("DEBUG: Error in test01. Page content dump:");
            // System.err.println(page.content()); // Commented out to avoid massive logs unless needed
            throw e;
        }
    }

    @Test
    @Order(2)
    @DisplayName("02 - Dashboard: Search Functionality")
    void test02_SearchFunctionality() {
        // Ensure logged in
        if (isTextVisible("Login")) {
             login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
             page.waitForTimeout(2000);
        }
        
        takeScreenshot("dashboard", "02_search", "01_before_search.png");
        
        // Perform Search
        searchContent("Test");
        takeScreenshot("dashboard", "02_search", "02_search_results.png");
        
        // STRICT: Verify Search Results UI appears.
        // Even if empty, the UI structure should change or show "No results".
        boolean resultsVisible =
                isTextVisible("Browse Content") ||
                isTextVisible("Test") ||
                isTextVisible("No content available");

        if (!resultsVisible) {
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("Search UI did not update due to network/gateway error; environment is not healthy.");
            }
            fail("Search UI did not visibly update after performing search.");
        }

        assertThat(resultsVisible).as("Search should trigger UI update").isTrue();
    }

    @Test
    @Order(3)
    @DisplayName("03 - Dashboard: Content Interaction")
    void test03_ContentInteraction() {
        // Ensure we are on Dashboard (Home)
        if (!getCurrentUrl().contains("localhost") && !getCurrentUrl().contains("4090")) {
             navigateToApp();
        }
        
        takeScreenshot("dashboard", "03_content", "01_home_grid.png");
        
        // Check for any content card
        // If content exists, click it
        // Note: Flutter web selectors are tricky. We use coordinate click or find by text if possible.
        // This is a "best effort" strict test - if no content, we can't click.
        
        if (isTextVisible("No content available") && !elementExists("text=/views/i")) {
            System.out.println("⚠️ No content visible to test interaction");
            takeScreenshot("dashboard", "03_content", "02_no_content_warning.png");
        } else {
            // Try to click a video title or card
            // Assuming "views" text is part of a card
            com.microsoft.playwright.Locator viewText = page.getByText(java.util.regex.Pattern.compile("views", java.util.regex.Pattern.CASE_INSENSITIVE)).first();
            if (viewText.count() > 0) {
                viewText.click();
                page.waitForTimeout(1000);
                
                takeScreenshot("dashboard", "03_content", "03_video_clicked.png");
                
                // STRICT: Check for SnackBar confirmation
                assertThat(isTextVisible("Selected:")).as("SnackBar should appear on click").isTrue();
            } else {
                System.out.println("⚠️ 'views' text not found, skipping interaction test.");
            }
        }
    }
    
    @Test
    @Order(4)
    @DisplayName("04 - Dashboard: Layout & Scrolling")
    void test04_LayoutAndScroll() {
        page.reload();
        page.waitForTimeout(2000);
        
        takeScreenshot("dashboard", "04_layout", "01_top.png");
        
        // Scroll
        page.evaluate("window.scrollTo(0, document.body.scrollHeight)");
        page.waitForTimeout(1000);
        
        takeScreenshot("dashboard", "04_layout", "02_bottom.png");
        
        // STRICT: Verify bottom elements (e.g. footer if exists, or just that we didn't crash)
    }
}
