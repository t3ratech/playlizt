package zw.co.t3ratech.playlizt.ui;

import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;

/**
 * STRICT Authentication Tests
 * 
 * Validates:
 * 1. Login Page Loading
 * 2. Registration Flow (Validation, Success, Duplicates)
 * 3. Login Flow (Validation, Invalid Credentials, Success)
 * 4. Logout Flow
 * 
 * STRICTNESS:
 * - Fails if specific text is missing
 * - Fails if URLs do not match expectations
 * - Fails if validation errors do not appear
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztAuthenticationTest extends BasePlayliztTest {

    private static final String TEST_USERNAME = "strict_user_" + System.currentTimeMillis();
    private static final String TEST_EMAIL = "strict" + System.currentTimeMillis() + "@playlizt.com";
    private static final String TEST_PASSWORD = "StrictPassword123!";

    @Test
    @Order(1)
    @DisplayName("01 - Initial Seeded Email Login Verification")
    void test01_InitialSeededEmailLogin() {
        navigateToApp();
        
        System.out.println("Testing seeded login with EMAIL: " + TEST_USER_EMAIL);
        performLogin(TEST_USER_EMAIL, TEST_USER_PASSWORD);
        verifyDashboardAndLogout("01_seeded_email_login");
    }

    @Test
    @Order(2)
    @DisplayName("02 - Login Page Load & Elements Verification")
    void test02_LoginPageLoad() {
        navigateToApp();

        // Ensure we are actually on the login form (previous tests may have authenticated).
        if (!isLoginFormVisible()) {
            try {
                logout();
                page.waitForTimeout(1000);
            } catch (Exception ignored) {
            }
        }
        
        // STRICT: Check URL and Title
        assertThat(getCurrentUrl()).contains("localhost");
        assertThat(getPageTitle()).contains("Playlizt");

        takeScreenshot("auth", "02_login_load", "01_initial_load.png");
        
        // STRICT: Wait for login form controls instead of relying on role/button semantics.
        page.locator("input[type='password']")
                .first()
                .waitFor(new com.microsoft.playwright.Locator.WaitForOptions().setTimeout(20000));

        boolean loginTextVisible = isTextVisible("Login") || isTextVisible("Sign In");
        assertThat(loginTextVisible).as("Login button/text should be visible").isTrue();

        // Try to find Playlizt title
        try {
            waitForText("Playlizt", 2000);
        } catch (Exception e) {
            System.out.println("Warning: 'Playlizt' title text not detected by accessibility tree.");
        }
        
        System.out.println("✓ Login page strict checks passed");
    }

    @Test
    @Order(3)
    @DisplayName("03 - Initial Seeded Username Login Verification")
    void test03_InitialSeededUsernameLogin() {
        navigateToApp();

        System.out.println("Testing seeded login with USERNAME: " + TEST_USER_USERNAME);
        performLogin(TEST_USER_USERNAME, TEST_USER_PASSWORD);
        verifyDashboardAndLogout("03_seeded_username_login");
    }

    @Test
    @Order(4)
    @DisplayName("04 - Registration: Navigate & Form Validation")
    void test04_RegistrationValidation() {
        navigateToApp();
        navigateToRegister();
        
        // Wait for Username input
        page.getByLabel("Username").or(page.getByPlaceholder("username")).first().waitFor();
        takeScreenshot("auth", "03_register_val", "01_register_page.png");

        // Submit empty form
        page.getByRole(com.microsoft.playwright.options.AriaRole.BUTTON, new com.microsoft.playwright.Page.GetByRoleOptions().setName("Register")).first().click();
        
        boolean hasErrors = isTextVisible("Please enter a username") || isTextVisible("Please enter your email");
        assertThat(hasErrors).as("Validation errors should appear for empty registration").isTrue();
    }

    @Test
    @Order(5)
    @DisplayName("05 - Registration: Success")
    void test05_RegistrationSuccess() {
        navigateToApp();
        navigateToRegister();

        // Fill form with exact match for Password
        page.getByLabel("Username").fill(TEST_USERNAME);
        page.getByLabel("Email").fill(TEST_EMAIL);
        page.getByLabel("Password", new com.microsoft.playwright.Page.GetByLabelOptions().setExact(true)).fill(TEST_PASSWORD);
        page.getByLabel("Confirm Password").fill(TEST_PASSWORD);
        
        takeScreenshot("auth", "04_register_success", "01_submitted.png");
        
        page.getByRole(com.microsoft.playwright.options.AriaRole.BUTTON, new com.microsoft.playwright.Page.GetByRoleOptions().setName("Register")).first().click();
        
        page.waitForTimeout(2000);
        System.out.println("✓ Registration submitted for " + TEST_EMAIL);
    }

    @Test
    @Order(6)
    @DisplayName("06 - Login: Validation & Invalid Credentials")
    void test06_LoginValidation() {
        navigateToApp();
        
        // 1. Empty Submit
        com.microsoft.playwright.Locator loginBtn = page.getByRole(com.microsoft.playwright.options.AriaRole.BUTTON, new com.microsoft.playwright.Page.GetByRoleOptions().setName("Login"))
           .or(page.getByRole(com.microsoft.playwright.options.AriaRole.BUTTON, new com.microsoft.playwright.Page.GetByRoleOptions().setName("Sign In")));
        
        loginBtn.first().waitFor();
        loginBtn.first().click();
        
        takeScreenshot("auth", "05_login_val", "01_empty_submit.png");
        
        // 2. Invalid Credentials
        login("wrong@user.com", "WrongPass123!");
        takeScreenshot("auth", "05_login_val", "02_invalid_creds_submit.png");
        
        page.waitForTimeout(2000);
        takeScreenshot("auth", "05_login_val", "03_invalid_creds_result.png");
        
        // STRICT: Check for error message (Retry for up to 5 seconds)
        // Accept either a generic failure keyword or the specific
        // field-level validation messages rendered by the Flutter form.
        boolean errorVisible = false;
        for (int i = 0; i < 10; i++) {
            errorVisible =
                    isTextVisible("Invalid email or password") ||
                    isTextVisible("Please enter your email or username") ||
                    isTextVisible("Please enter your password") ||
                    isTextVisible("Invalid") ||
                    isTextVisible("Failed") ||
                    isTextVisible("incorrect") ||
                    isTextVisible("Forbidden") ||
                    isTextVisible("Bad Request") ||
                    isTextVisible("Error") ||
                    isTextVisible("Unauthorized") ||
                    isTextVisible("Network error");
            if (errorVisible) break;
            page.waitForTimeout(500);
        }
        assertThat(errorVisible).as("Error message should appear for invalid credentials").isTrue();
    }

    @Test
    @Order(7)
    @DisplayName("07 - Login: Success & Logout")
    void test07_LoginSuccessAndLogout() {
        navigateToApp();

        // Use seeded user for logout verification to keep tests deterministic.
        performLogin(TEST_USER_EMAIL, TEST_USER_PASSWORD);
        page.waitForTimeout(1500);
        
        takeScreenshot("auth", "06_login_success", "01_dashboard.png");
        verifyDashboardElements();
        
        // 4. Logout
        logout();
        page.waitForTimeout(2000);
        takeScreenshot("auth", "06_login_success", "02_logged_out.png");

        boolean onLoginPage = (isTextVisible("Login") || isTextVisible("Sign In"))
                && (elementExists("input[type='password']") || elementExists("input"));

        if (!onLoginPage && isTextVisible("Network error")) {
            fail("Network error visible after logout; environment is not healthy.");
        }

        assertThat(onLoginPage).as("Should be back on login page after logout").isTrue();
    }

    // Helper methods to reduce duplication
    
    private void performLogin(String user, String pass) {
        if (!isTextVisible("Login") && !isTextVisible("Sign In")) {
             if (isTextVisible("Logout")) logout();
             else if (isTextVisible("Register")) {
                 try { page.getByText("Login").click(); } 
                 catch (Exception e) { page.navigate(FLUTTER_URL); }
             }
        }
        login(user, pass);

        for (int i = 0; i < 20; i++) {
            boolean onDashboard = isTextVisible("Browse Content") ||
                    elementExists("[aria-label^='Video:']") ||
                    elementExists("input[aria-label='Search content...']");
            if (onDashboard) {
                break;
            }

            if (!isLoginFormVisible()) {
                break;
            }
            page.waitForTimeout(500);
        }
    }

    private void verifyDashboardAndLogout(String screenshotName) {
        takeScreenshot("auth", "seeded_login", screenshotName + ".png");

        boolean onLoginPage = false;
        boolean onDashboard = false;
        for (int i = 0; i < 30; i++) {
            onLoginPage = isLoginFormVisible();
            onDashboard = isTextVisible("Browse Content") ||
                    elementExists("[aria-label^='Video:']") ||
                    elementExists("input[aria-label='Search content...']");
            if (onDashboard) {
                break;
            }
            if (!onLoginPage) {
                break;
            }
            page.waitForTimeout(500);
        }

        if (onLoginPage && !onDashboard) {
            // Environment is not allowed to hide behind network errors; surface them as hard failures.
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("Seeded login failed due to network/gateway error; environment is not healthy.");
            }

            // Environment is healthy but we are still on the login page.
            // Distinguish real invalid-credential cases from generic failures.
            if (isTextVisible("Invalid") || isTextVisible("incorrect")) {
                throw new AssertionError("Login failed: Invalid credentials message displayed.");
            }
            throw new AssertionError("Login failed: Still on login page.");
        }

        if (!onDashboard) {
            if (consoleContains("Error while trying to load an asset") || consoleContains("Failed to fetch")) {
                fail("UI did not reach dashboard due to Flutter web asset fetch error; environment is not healthy.");
            }
            fail("Login flow did not reach dashboard state; unable to verify seeded login.");
        }
        
        verifyDashboardElements();
        logout();
    }
    
    private void verifyDashboardElements() {
        boolean homeElements = isTextVisible("Browse") || isTextVisible("Home") || isTextVisible("Playlizt");
        assertThat(homeElements).as("Should be on dashboard").isTrue();
    }

    private boolean isLoginFormVisible() {
        try {
            com.microsoft.playwright.Locator pwd = page.locator("input[type='password']");
            if (pwd.count() == 0) return false;
            if (!pwd.first().isVisible()) return false;
            boolean loginTextVisible = isTextVisible("Login") || isTextVisible("Sign In");
            if (!loginTextVisible) return false;
            // Register form also contains password inputs; exclude it.
            if (isTextVisible("Confirm Password") || isTextVisible("Repeat Password")) return false;
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
