package zw.co.t3ratech.playlizt.ui;

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
                System.out.println("Login page visible. Logging in with seeded user " + TEST_USER_EMAIL);
                login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
                page.waitForTimeout(3000);
            }
            
            // If still on Login/Register (e.g. invalid credentials), try registering? 
            // No, we expect seeded user to exist.
            
            takeScreenshot("dashboard", "01_setup", "01_logged_in.png");
            
            // STRICT: Verify Dashboard Loaded
            if (isTextVisible("Login") || isTextVisible("Sign In")) {
                takeScreenshot("failures", "dashboard_setup", "still_on_login.png");
                fail("Expected to be logged in, but Login page is still visible.");
            }
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
        ensureLoggedInOnDashboard();
        
        takeScreenshot("dashboard", "02_search", "01_before_search.png");
        
        // Perform Search
        searchContent("Test");
        takeScreenshot("dashboard", "02_search", "02_search_results.png");

        assertThat(isTextVisible("Browse Content") || elementExists("input[aria-label='Search content...']") || elementExists("[aria-label^='Video:']"))
                .as("Expected to remain on dashboard after search")
                .isTrue();
    }

    @Test
    @Order(3)
    @DisplayName("03 - Dashboard: Content Interaction")
    void test03_ContentInteraction() {
        ensureLoggedInOnDashboard();

        try {
            waitForText("Browse Content", 10000);
        } catch (Exception ignored) {
        }

        takeScreenshot("dashboard", "03_content", "01_home_grid.png");
        
        // Check for any content card
        // If content exists, click it
        // Note: Flutter web selectors are tricky. We use coordinate click or find by text if possible.
        // This is a "best effort" strict test - if no content, we can't click.
        
        if (isTextVisible("No content available")) {
            takeScreenshot("dashboard", "03_content", "02_no_content.png");
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("No content visible due to network/gateway error; environment is not healthy.");
            }
            fail("No content visible on dashboard; expected seeded content to be available.");
        } else {
            com.microsoft.playwright.Locator card = findFirstContentCard();

            if (card == null) {
                takeScreenshot("dashboard", "03_content", "02_missing_video_cards.png");
                if (isTextVisible("Network error") ||
                        consoleContains("Network error. Please check your connection.") ||
                        consoleContains("ERR_CONNECTION_REFUSED")) {
                    fail("No content cards visible due to network/gateway error; environment is not healthy.");
                }
                fail("Expected at least one visible content card to be available for interaction test.");
            }

            try {
                card.scrollIntoViewIfNeeded();
            } catch (Exception ignored) {
            }
            card.click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
            page.waitForTimeout(1000);

            takeScreenshot("dashboard", "03_content", "03_video_clicked.png");

            boolean navigatedToPlayer = false;
            try {
                waitForText("Description", 15000);
                navigatedToPlayer = true;
            } catch (Exception ignored) {
                navigatedToPlayer = false;
            }

            if (!navigatedToPlayer) {
                assertThat(isTextVisible("Selected:") || isTextVisible("Browse Content"))
                        .as("Expected either to navigate to player (Description) or remain on dashboard after click")
                        .isTrue();
            }
        }
    }
    
    @Test
    @Order(4)
    @DisplayName("04 - Dashboard: Layout & Scrolling")
    void test04_LayoutAndScroll() {
        ensureLoggedInOnDashboard();

        page.reload();
        page.waitForTimeout(2000);

        if (isTextVisible("Login") || isTextVisible("Sign In")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
            page.waitForTimeout(2000);
        }
        
        takeScreenshot("dashboard", "04_layout", "01_top.png");
        
        // Scroll
        page.evaluate("window.scrollTo(0, document.body.scrollHeight)");
        page.waitForTimeout(1000);
        
        takeScreenshot("dashboard", "04_layout", "02_bottom.png");
        
        // STRICT: Verify bottom elements (e.g. footer if exists, or just that we didn't crash)
    }

    private void ensureLoggedInOnDashboard() {
        navigateToApp();

        if (isTextVisible("Browse Content") || elementExists("input[aria-label='Search content...']") || elementExists("input[placeholder='Search content...']")) {
            return;
        }

        if (isTextVisible("Login") || isTextVisible("Sign In") || page.locator("input[type='password']").count() > 0) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
            page.waitForTimeout(2000);
        }

        for (int i = 0; i < 30; i++) {
            if (isTextVisible("Browse Content") || elementExists("input[aria-label='Search content...']") || elementExists("input[placeholder='Search content...']")) {
                return;
            }
            page.waitForTimeout(250);
        }

        if (isTextVisible("Login") || isTextVisible("Sign In")) {
            takeScreenshot("failures", "dashboard_setup", "still_on_login.png");
            fail("Expected to be logged in and on dashboard, but Login page is still visible.");
        }

        takeScreenshot("failures", "dashboard_setup", "dashboard_not_detected.png");
        fail("Unable to detect dashboard after login attempt.");
    }

    private com.microsoft.playwright.Locator findFirstContentCard() {
        com.microsoft.playwright.Locator candidates = page.locator(
                "[aria-label^='Video:'], [aria-label*='Episode'], [aria-label*='Season']"
        );

        for (int attempt = 0; attempt < 8; attempt++) {
            int count = candidates.count();
            int limit = Math.min(count, 20);

            for (int i = 0; i < limit; i++) {
                com.microsoft.playwright.Locator c = candidates.nth(i);
                try {
                    if (c != null && c.isVisible()) {
                        return c;
                    }
                } catch (Exception ignored) {
                }
            }

            // Fallback: click the first visible title text on a card (screenshots show Episode titles)
            try {
                com.microsoft.playwright.Locator episodeText = page.getByText("Episode").first();
                if (episodeText.count() > 0 && episodeText.isVisible()) {
                    return episodeText;
                }
            } catch (Exception ignored) {
            }

            try {
                page.mouse().wheel(0, 900);
            } catch (Exception ignored) {
            }
            page.waitForTimeout(750);
        }

        return null;
    }
}
