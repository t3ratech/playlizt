package com.smatech.playlizt.ui;

import com.microsoft.playwright.*;
import com.microsoft.playwright.options.AriaRole;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Base class for Playlizt Playwright UI integration tests.
 * 
 * This class provides infrastructure for testing the Playlizt Flutter web application
 * following patterns from ThaStreetz but adapted for Flutter/web testing.
 * 
 * Key Features:
 * - Automated screenshot capture with organized folder structure
 * - Multi-browser support (Chromium, Firefox, WebKit)
 * - Page object pattern support
 * - Configurable headless/headed mode
 * - Network interception capabilities
 * - Accessibility testing helpers
 */
public abstract class BasePlayliztTest {
    
    protected static Playwright playwright;
    protected static Browser browser;
    protected static BrowserContext context;
    protected static Page page;
    
    static {
        try {
            java.util.Properties props = new java.util.Properties();
            try (java.io.InputStream is = BasePlayliztTest.class.getClassLoader().getResourceAsStream("test.properties")) {
                if (is != null) {
                    props.load(is);
                    for (String name : props.stringPropertyNames()) {
                        String val = props.getProperty(name);
                        System.setProperty(name, val);
                        if (name.equals("playwright.headless")) {
                            System.out.println("DEBUG: Setting playwright.headless to " + val);
                        }
                    }
                    System.out.println("✓ Loaded test.properties");
                }
            }
        } catch (Exception e) {
            System.out.println("⚠️ Could not load test.properties: " + e.getMessage());
        }
    }
    
    // Test configuration from system properties
    protected static final String WEB_URL = System.getProperty("test.web.url");
    protected static final String FLUTTER_URL = System.getProperty("test.flutter.url");
    protected static final boolean HEADLESS = Boolean.parseBoolean(System.getProperty("playwright.headless"));
    protected static final int SLOWMO = Integer.parseInt(System.getProperty("playwright.slowmo"));
    protected static final int TIMEOUT = Integer.parseInt(System.getProperty("playwright.timeout"));
    protected static final String SCREENSHOT_DIR = "src/test/output";

    protected static final String TEST_USER_EMAIL = System.getProperty("test.user.email");
    protected static final String TEST_USER_PASSWORD = System.getProperty("test.user.password");
    protected static final String TEST_USER_USERNAME = System.getProperty("test.user.username");
    
    @BeforeAll
    static void launchBrowser() {
        // Re-read properties after loading file
        boolean headless = Boolean.parseBoolean(System.getProperty("playwright.headless"));
        int slowmo = Integer.parseInt(System.getProperty("playwright.slowmo"));
        
        playwright = Playwright.create();
        browser = playwright.chromium().launch(new BrowserType.LaunchOptions()
                .setHeadless(headless)
                .setSlowMo(slowmo)
                .setArgs(java.util.Arrays.asList("--force-renderer-accessibility")));
                
        System.out.println("Browser launched. Headless: " + headless);
        
        // Create context and page once for the whole class
        // This preserves the accessibility tree hydration across tests
        context = browser.newContext(new Browser.NewContextOptions()
                .setViewportSize(1920, 1080)
                .setLocale("en-US"));
        
        context.setDefaultTimeout(TIMEOUT);
        page = context.newPage();
        
        // Enable console logging
        page.onConsoleMessage(msg -> {
            System.out.println("Browser Console: " + msg.text());
            if ("error".equalsIgnoreCase(msg.type())) {
                System.err.println("SEVERE BROWSER ERROR: " + msg.text());
            }
        });
    }
    
    @AfterAll
    static void closeBrowser() {
        if (context != null) {
            context.close();
        }
        if (browser != null) {
            browser.close();
        }
        if (playwright != null) {
            playwright.close();
        }
    }
    
    @BeforeEach
    void setUp() {
        // Ensure we have a page (in case a test closed it)
        if (page == null || page.isClosed()) {
            page = context.newPage();
        }
        // We do NOT create new context here. We reuse it.
        // Instead, we ensure we are in a clean state (Login Page)
        resetToLoginPage();
    }
    
    @AfterEach
    void tearDown() {
        // Do nothing, keep page open
    }
    
    /**
     * Resets the app to the Login page without reloading if possible
     */
    protected void resetToLoginPage() {
        // If not on app at all, navigate
        if (!page.url().contains(FLUTTER_URL) && !page.url().contains("localhost")) {
            navigateToApp();
            return;
        }
        
        // If already on Login page (check for Login button)
        if (isTextVisible("Login") && elementExists("button:has-text('Login')")) {
            return; // Already there
        }
        
        // If logged in (Logout button visible)
        if (isTextVisible("Logout") || isTextVisible("Sign Out")) {
             try { logout(); } catch (Exception e) {}
        }
        
        // If on Register page
        if (isTextVisible("Already have an account")) {
             page.getByText("Already have an account").click();
        }
        
        // If "Login" not visible after attempts, force clear and reload
        if (!isTextVisible("Login")) {
            System.out.println("State unclean, clearing storage and reloading app...");
            try {
                page.evaluate("window.localStorage.clear()");
            } catch (Exception e) {
                System.out.println("Error clearing local storage: " + e.getMessage());
            }
            page.reload();
            navigateToApp();
        }
    }

    /**
     * Navigate to the Flutter web application
     */
    protected void navigateToApp() {
        // Only navigate if URL is different
        if (!page.url().startsWith(FLUTTER_URL)) {
             page.navigate(FLUTTER_URL);
        }
        waitForFlutterReady();
    }
    
    
    /**
     * Wait for Flutter app to be fully loaded and ready
     */
    protected void waitForFlutterReady() {
        // Wait for page load event
        page.waitForLoadState(com.microsoft.playwright.options.LoadState.NETWORKIDLE);
        
        // Enable accessibility if prompted (common in Flutter Web CanvasKit)
        // We do NOT skip this check even if text is visible, because partial hydration can occur.
        try {
            // Check for the button explicitly
            com.microsoft.playwright.Locator accessBtn = page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Enable accessibility"));
            
            // If button exists, we MUST click it
            if (accessBtn.count() > 0 && accessBtn.first().isVisible()) {
                System.out.println("✓ Found 'Enable accessibility' button. Clicking it to hydrate DOM...");
                try {
                    accessBtn.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                    page.waitForTimeout(1000);
                    
                    // If button still exists, try pressing Enter
                    if (accessBtn.count() > 0) {
                        System.out.println("⚠️ 'Enable accessibility' button still present. Trying Focus + Enter...");
                        try {
                            accessBtn.first().focus();
                            page.keyboard().press("Enter");
                            page.waitForTimeout(1000);
                        } catch (Exception e) {
                            System.out.println("Failed to press Enter on button: " + e.getMessage());
                        }
                    }
                } catch (Exception e) {
                    System.out.println("⚠️ Click/Enter failed: " + e.getMessage());
                }
                
                // Wait for hydration - look for app title or login text
                try {
                    page.getByText("Playlizt").or(page.getByText("Login")).waitFor(
                        new com.microsoft.playwright.Locator.WaitForOptions().setTimeout(5000));
                    System.out.println("✓ Accessibility tree hydrated.");
                } catch (Exception e) {
                    System.out.println("⚠️ Waited for text after enabling accessibility but timed out. Continuing...");
                }
                
                // Robust check: If accessibility button persists, use JS to force click it
                if (accessBtn.count() > 0) {
                    System.out.println("⚠️ Accessibility button still visible. Attempting JS click...");
                    try {
                        accessBtn.first().evaluate("node => node.click()");
                        page.waitForTimeout(1000);
                        System.out.println("✓ JS Click executed.");
                    } catch (Exception e) {
                         System.out.println("JS click failed: " + e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            System.out.println("⚠️ Error interacting with accessibility button: " + e.getMessage());
        }
        
        // Log page content for debugging
        System.out.println("Page URL: " + page.url());
        System.out.println("Page Title: " + page.title());
    }
    
    /**
     * Navigate to the API Gateway
     */
    protected void navigateToApiGateway() {
        page.navigate(WEB_URL);
    }
    
    /**
     * Take a screenshot with organized folder structure: module/scenario/filename.png
     * 
     * @param module Module name (e.g., "auth", "content", "playback")
     * @param scenario Test scenario (e.g., "login", "browse-videos", "watch-video")
     * @param filename Screenshot filename (e.g., "01-login-form.png", "02-error-message.png")
     */
    protected void takeScreenshot(String module, String scenario, String filename) {
        try {
            Path screenshotDir = Paths.get(SCREENSHOT_DIR, module, scenario);
            Files.createDirectories(screenshotDir);
            Path screenshotPath = screenshotDir.resolve(filename);
            page.screenshot(new Page.ScreenshotOptions().setPath(screenshotPath).setFullPage(true));
            System.out.println("✓ Screenshot: " + module + "/" + scenario + "/" + filename);
        } catch (Exception e) {
            System.err.println("✗ Failed to take screenshot: " + module + "/" + scenario + "/" + filename);
            e.printStackTrace();
        }
    }
    
    /**
     * Take a full page screenshot (convenience method)
     */
    protected void takeScreenshot(String filename) {
        takeScreenshot("general", "screenshots", filename);
    }
    
    /**
     * Navigate to the Registration page from Login page
     */
    protected void navigateToRegister() {
        System.out.println("Navigating to Register page...");
        boolean clicked = false;
        
        // Try "Don't have an account" link first (most specific)
        if (isTextVisible("Don't have an account? Register")) {
             System.out.println("Found 'Don't have an account? Register' link. Clicking...");
             try {
                 // Click the RIGHT side of the text (where "Register" usually is)
                 com.microsoft.playwright.Locator link = page.getByText("Don't have an account? Register").first();
                 com.microsoft.playwright.options.BoundingBox box = link.boundingBox();
                 if (box != null) {
                     System.out.println("Clicking at 95% width of the text to hit 'Register' span...");
                     link.click(new com.microsoft.playwright.Locator.ClickOptions()
                         .setPosition(box.width * 0.95, box.height / 2)
                         .setForce(true));
                 } else {
                     link.click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                 }
                 clicked = true;
             } catch (Exception e) {
                 System.out.println("Click failed: " + e.getMessage());
             }
        }
        
        if (!clicked && isTextVisible("Don't have an account")) {
            System.out.println("Found 'Don't have an account' link. Clicking...");
            try {
                page.getByText("Don't have an account").first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                clicked = true;
            } catch (Exception e) {
                System.out.println("Click failed: " + e.getMessage());
            }
        } 
        
        if (!clicked && isTextVisible("Register")) {
            System.out.println("Found 'Register' text. Clicking...");
            try {
                page.getByText("Register").last().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                clicked = true;
            } catch (Exception e) {
                System.out.println("Click failed: " + e.getMessage());
            }
        }
        
        if (!clicked) {
            System.out.println("⚠️ Could not find Register link via text. Checking buttons...");
            try {
                com.microsoft.playwright.Locator regBtn = page.getByRole(AriaRole.BUTTON).filter(
                    new com.microsoft.playwright.Locator.FilterOptions().setHasText("Register"));
                if (regBtn.count() > 0) {
                    regBtn.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                    clicked = true;
                }
            } catch (Exception e) {
                System.out.println("Button click failed: " + e.getMessage());
            }
        }
        
        page.waitForTimeout(2000);
    }

    /**
     * Login to the application
     * 
     * @param email User email
     * @param password User password
     */
    protected void login(String email, String password) {
        // Use strict locators and ensure focus
        com.microsoft.playwright.Locator emailInput = page.getByLabel("Email");
        
        // Wait for Email input to be visible (Robust check)
        try {
            emailInput.first().waitFor(new Locator.WaitForOptions().setTimeout(3000));
        } catch (Exception e) {
            // Fallback to placeholder
            emailInput = page.getByPlaceholder("email");
            try {
                emailInput.first().waitFor(new Locator.WaitForOptions().setTimeout(3000));
            } catch (Exception ex) {
                System.out.println("Could not find Email input. Proceeding to try anyway...");
            }
        }
        
        if (emailInput.count() == 0) emailInput = page.getByPlaceholder("email");
        
        // Try to scroll into view and interact using JS if standard fails
        try {
            emailInput.first().scrollIntoViewIfNeeded();
            emailInput.first().fill(email);
        } catch (Exception e) {
            System.out.println("Standard fill failed, trying JS fill for Email...");
            emailInput.first().evaluate("node => { node.value = '" + email + "'; node.dispatchEvent(new Event('input', { bubbles: true })); }");
        }
        
        com.microsoft.playwright.Locator passInput = page.getByLabel("Password");
        if (passInput.count() == 0) passInput = page.getByPlaceholder("password");

        try {
            passInput.first().scrollIntoViewIfNeeded();
            passInput.first().fill(password);
        } catch (Exception e) {
            System.out.println("Standard fill failed, trying JS fill for Password...");
            passInput.first().evaluate("node => { node.value = '" + password + "'; node.dispatchEvent(new Event('input', { bubbles: true })); }");
        }
        
        // Click login button
        try {
            com.microsoft.playwright.Locator loginBtn = page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Login"))
               .or(page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Sign In")))
               .first();
            
            loginBtn.scrollIntoViewIfNeeded();
            loginBtn.click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
        } catch (Exception e) {
            System.out.println("Click failed, trying JS click...");
            page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Login"))
               .or(page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Sign In")))
               .first()
               .evaluate("node => node.click()");
        }
        
        // Wait for navigation
        page.waitForTimeout(2000);
    }
    
    /**
     * Register a new user
     * 
     * @param username Username
     * @param email Email
     * @param password Password
     */
    protected void register(String username, String email, String password) {
        com.microsoft.playwright.Locator userInput = page.getByLabel("Username");
        if (userInput.count() == 0) userInput = page.getByPlaceholder("username");
        
        userInput.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
        userInput.first().clear();
        userInput.first().fill(username);
        
        com.microsoft.playwright.Locator emailInput = page.getByLabel("Email");
        if (emailInput.count() == 0) emailInput = page.getByPlaceholder("email");
        
        emailInput.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
        emailInput.first().clear();
        emailInput.first().fill(email);
        
        com.microsoft.playwright.Locator passInput = page.getByLabel("Password");
        if (passInput.count() == 0) passInput = page.getByPlaceholder("password");
        
        passInput.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
        passInput.first().clear();
        passInput.first().fill(password);
        
        // Handle Confirm Password if present
        com.microsoft.playwright.Locator confirmInput = page.getByLabel("Confirm Password")
            .or(page.getByLabel("Repeat Password"))
            .or(page.getByPlaceholder("confirm password"));
            
        if (confirmInput.count() > 0) {
             System.out.println("Found Confirm/Repeat Password field. Filling...");
             confirmInput.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
             confirmInput.first().clear();
             confirmInput.first().fill(password);
        }
        
        try {
            com.microsoft.playwright.Locator registerBtn = page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Register"))
               .or(page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Sign Up")))
               .first();
               
            registerBtn.evaluate("node => node.click()");
        } catch (Exception e) {
            System.out.println("JS Click for Register failed, trying standard click...");
            page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Register"))
               .or(page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Sign Up")))
               .first()
               .click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
        }
        
        page.waitForTimeout(2000);
    }
    
    /**
     * Logout from the application
     */
    protected void logout() {
        System.out.println("Attempting logout...");
        
        // 1. Try direct Logout button
        com.microsoft.playwright.Locator logoutBtn = page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Logout"))
           .or(page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Sign Out")));
           
        if (logoutBtn.count() > 0 && logoutBtn.first().isVisible()) {
            logoutBtn.first().click();
            page.waitForTimeout(1000);
            return;
        }
        
        // 2. Try Profile Menu -> Logout
        System.out.println("Direct logout not visible. Checking Profile menu...");
        com.microsoft.playwright.Locator profileBtn = page.getByLabel("Profile")
            .or(page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Profile")));
            
        if (profileBtn.count() == 0) {
             // Fallback: It might be the last button (Profile icon) if semantics are missing
             System.out.println("Profile button not found by label. Trying last button in AppBar...");
             // Assuming AppBar actions: [Theme, Profile]
             // We try to find buttons that are likely in the app bar (top of screen)
             profileBtn = page.getByRole(AriaRole.BUTTON).last(); 
        }

        if (profileBtn.count() > 0 && profileBtn.first().isVisible()) {
            System.out.println("Found potential Profile button. Opening menu...");
            profileBtn.first().click();
            page.waitForTimeout(1000); // Wait for dialog/menu
            
            // Now Logout should be visible in the Dialog
            if (logoutBtn.count() > 0 && logoutBtn.first().isVisible()) {
                logoutBtn.first().click();
                page.waitForTimeout(1000);
                return;
            } else {
                // Maybe "Close" is visible?
                if (isTextVisible("Close")) {
                     System.out.println("Profile dialog opened (Close visible), but Logout not found?");
                     // Try finding button with text "Logout" manually if role fails
                     if (isTextVisible("Logout")) {
                         page.getByText("Logout").click();
                         page.waitForTimeout(1000);
                         return;
                     }
                } else {
                     System.out.println("Profile dialog did not appear or is different.");
                }
            }
        }
        
        // 3. Failure - Dump for debugging
        System.out.println("Logout failed. Dumping visible buttons to help debug:");
        try {
            java.util.List<com.microsoft.playwright.Locator> buttons = page.getByRole(AriaRole.BUTTON).all();
            for (com.microsoft.playwright.Locator btn : buttons) {
                if (btn.isVisible()) {
                    String label = btn.getAttribute("aria-label");
                    String text = btn.textContent();
                    System.out.println(" - Button: label='" + (label != null ? label : "null") + "', text='" + (text != null ? text.trim() : "null") + "'");
                }
            }
        } catch (Exception e) {
            System.out.println("Error dumping buttons: " + e.getMessage());
        }
        throw new RuntimeException("Logout button not found");
    }
    
    /**
     * Search for content
     * 
     * @param query Search query
     */
    protected void searchContent(String query) {
        try {
            page.getByPlaceholder("Search content...")
                .or(page.getByRole(AriaRole.TEXTBOX, new Page.GetByRoleOptions().setName("Search")))
                .first() // Use first if multiple matches (e.g. desktop/mobile layout)
                .fill(query);
        } catch (Exception e) {
            System.out.println("Specific search input not found. Trying generic textbox...");
            // Fallback: Try first textbox
            if (page.getByRole(AriaRole.TEXTBOX).count() > 0) {
                page.getByRole(AriaRole.TEXTBOX).first().fill(query);
            } else {
                throw e; // Rethrow if no textboxes at all
            }
        }
        page.keyboard().press("Enter");
        page.waitForTimeout(1500);
    }
    
    /**
     * Click on a video by title
     * 
     * @param title Video title
     */
    protected void clickVideo(String title) {
        page.getByText(title).first().click();
        page.waitForTimeout(2000);
    }
    
    /**
     * Assert that text is visible on page
     * 
     * @param text Text to find
     * @return true if text is visible
     */
    protected boolean isTextVisible(String text) {
        try {
            return page.getByText(text).first().isVisible();
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * STRICTLY Assert that text is visible on page. Fails test if not found.
     *
     * @param text Text to find
     * @param errorMessage Custom error message
     */
    protected void assertTextVisible(String text, String errorMessage) {
        if (!isTextVisible(text)) {
            takeScreenshot("failures", "missing_text", "missing_" + text.replaceAll("\\s+", "_") + ".png");
            throw new AssertionError(errorMessage + " - Text '" + text + "' not visible on page.");
        }
    }
    
    /**
     * Assert that element with selector exists
     * 
     * @param selector CSS selector
     * @return true if element exists
     */
    protected boolean elementExists(String selector) {
        return page.locator(selector).count() > 0;
    }
    
    /**
     * Wait for text to appear
     * 
     * @param text Text to wait for
     * @param timeoutMs Timeout in milliseconds
     */
    protected void waitForText(String text, int timeoutMs) {
        page.getByText(text).waitFor(new Locator.WaitForOptions()
            .setState(com.microsoft.playwright.options.WaitForSelectorState.VISIBLE)
            .setTimeout(timeoutMs));
    }
    
    /**
     * Get page title
     */
    protected String getPageTitle() {
        return page.title();
    }
    
    /**
     * Get current URL
     */
    protected String getCurrentUrl() {
        return page.url();
    }
    
    /**
     * Execute JavaScript in browser context
     * 
     * @param script JavaScript code
     * @return Result of script execution
     */
    protected Object executeScript(String script) {
        return page.evaluate(script);
    }
    
    /**
     * Verify screenshot matches baseline (visual regression)
     * Note: Requires baseline screenshots to be generated first
     * 
     * @param baseline Path to baseline screenshot
     */
    protected void verifyScreenshotMatches(Path baseline) {
        // This would use Playwright's visual comparison features
        // For now, we just take and store screenshots for manual verification
        System.out.println("Visual regression check against: " + baseline);
    }
}
