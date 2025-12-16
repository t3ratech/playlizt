package zw.co.t3ratech.playlizt.ui;

import com.microsoft.playwright.Page;
import com.microsoft.playwright.options.ColorScheme;
import org.junit.jupiter.api.*;

/**
 * Verifies UI adaptability to Light and Dark system themes.
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztThemeTest extends BasePlayliztTest {

    @Test
    @Order(1)
    @DisplayName("Theme Switching: Light vs Dark Mode Visual Verification")
    void testThemeSwitching() {
        System.out.println("Starting Theme Switching Test...");

        // 1. Force LIGHT Mode
        System.out.println("Setting system preference to LIGHT");
        page.emulateMedia(new Page.EmulateMediaOptions().setColorScheme(ColorScheme.LIGHT));
        
        navigateToApp();
        page.waitForTimeout(3000); // Wait for Flutter to render

        // Screenshot 1: Login Screen (Light)
        // Expected: White background, Black text, Light Logo
        takeScreenshot("theme", "switching", "01_login_light.png");
        
        // Login
        // Using seeded user credentials
        login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
        page.waitForTimeout(3000); // Wait for Dashboard

        // Screenshot 2: Dashboard (Light)
        // Expected: White App Bar, Light Logo
        takeScreenshot("theme", "switching", "02_dashboard_light.png");

        // 2. Switch to DARK Mode
        System.out.println("Switching system preference to DARK");
        page.emulateMedia(new Page.EmulateMediaOptions().setColorScheme(ColorScheme.DARK));
        page.waitForTimeout(3000); // Allow Flutter to react

        // Check if we are still logged in
        if (isTextVisible("Login")) {
            // Capture Login Dark first
            takeScreenshot("theme", "switching", "03_login_dark.png");
            
            // Re-login to capture Dashboard Dark
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
            page.waitForTimeout(3000);
            takeScreenshot("theme", "switching", "04_dashboard_dark.png");
        } else {
            // We are still on Dashboard
            // Screenshot 3: Dashboard (Dark)
            takeScreenshot("theme", "switching", "03_dashboard_dark.png");

            // Logout to check Login screen in Dark Mode
            logout();
            page.waitForTimeout(3000);

            // Screenshot 4: Login Screen (Dark)
            takeScreenshot("theme", "switching", "04_login_dark.png");
        }
        
        System.out.println("Theme test completed. Please manually inspect screenshots in src/test/output/theme/switching/");
    }
}
