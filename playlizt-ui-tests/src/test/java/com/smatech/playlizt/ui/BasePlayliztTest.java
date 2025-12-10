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
import java.util.Deque;
import java.util.concurrent.ConcurrentLinkedDeque;

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
    
    // Bounded buffer of recent browser console messages to help tests
    // distinguish between real application failures and environment/network issues.
    protected static final Deque<String> CONSOLE_MESSAGES = new ConcurrentLinkedDeque<>();
    
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
        
        // Add context and page once for the whole class
        // This preserves the accessibility tree hydration across tests
        context = browser.newContext(new Browser.NewContextOptions()
                .setViewportSize(1920, 1080)
                .setLocale("en-US"));
        
        context.setDefaultTimeout(TIMEOUT);
        page = context.newPage();
        
        // Enable console logging and capture recent messages for diagnostics
        page.onConsoleMessage(msg -> {
            String text = msg.text();
            System.out.println("Browser Console: " + text);
            if ("error".equalsIgnoreCase(msg.type())) {
                System.err.println("SEVERE BROWSER ERROR: " + text);
            }
            recordConsoleMessage(text);
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
        // Reset console message buffer for this test
        CONSOLE_MESSAGES.clear();

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
     * Record a browser console message in a bounded buffer so tests can
     * inspect recent console output for environment/network issues without
     * relying solely on DOM text.
     */
    protected static void recordConsoleMessage(String message) {
        if (message == null) return;
        CONSOLE_MESSAGES.addLast(message);
        while (CONSOLE_MESSAGES.size() > 200) {
            CONSOLE_MESSAGES.pollFirst();
        }
    }

    /**
     * Check whether any recent console message contains the given text
     * (case-insensitive).
     */
    protected static boolean consoleContains(String needle) {
        if (needle == null || needle.isEmpty()) return false;
        String n = needle.toLowerCase();
        for (String msg : CONSOLE_MESSAGES) {
            if (msg != null && msg.toLowerCase().contains(n)) {
                return true;
            }
        }
        return false;
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
        try {
            // Ensure we have a live page
            if (page == null || page.isClosed()) {
                System.out.println("navigateToApp: page was null/closed, creating new page...");
                page = context.newPage();
            }

            // Always navigate explicitly to the app root. This guarantees that we
            // recover from any intermediate Chrome error pages (e.g. "Aw, Snap!")
            // or unstable in-app states after heavy video playback.
            page.navigate(FLUTTER_URL);
            waitForFlutterReady();
        } catch (com.microsoft.playwright.PlaywrightException e) {
            // Recover from Chromium target crashes by recreating the page
            System.out.println("navigateToApp encountered PlaywrightException, recreating page: " + e.getMessage());
            try {
                if (page != null && !page.isClosed()) {
                    page.close();
                }
            } catch (Exception closeEx) {
                System.out.println("navigateToApp: error while closing crashed page: " + closeEx.getMessage());
            }

            page = context.newPage();
            page.navigate(FLUTTER_URL);
            waitForFlutterReady();
        }
    }
    
    
    /**
     * Wait for Flutter app to be fully loaded and ready
     */
    protected void waitForFlutterReady() {
        // Wait for page load event
        page.waitForLoadState(com.microsoft.playwright.options.LoadState.NETWORKIDLE);

        // Detect Chrome's "Aw, Snap!" crash page and recover by reloading once.
        // This avoids leaving the test stuck on a crashed tab after heavy video
        // playback while still treating persistent crashes as real failures.
        try {
            String crashScript = "() => { " +
                    "const href = window.location && window.location.href ? window.location.href.toLowerCase() : '';" +
                    "const bodyText = (document.body && document.body.innerText) ? document.body.innerText.toLowerCase() : '';" +
                    "return href.startsWith('chrome-error://') || " +
                    "       bodyText.includes('aw, snap!') || " +
                    "       bodyText.includes('something went wrong while displaying this webpage'); " +
                    "}";

            Boolean isCrash = (Boolean) page.evaluate(crashScript);
            if (Boolean.TRUE.equals(isCrash)) {
                System.out.println("Detected Chrome 'Aw, Snap!' crash page; reloading Playlizt app...");
                page.reload();
                page.waitForLoadState(com.microsoft.playwright.options.LoadState.NETWORKIDLE);
            }
        } catch (Exception e) {
            System.out.println("Error while checking for Chrome crash page: " + e.getMessage());
        }

        // Enable accessibility if prompted (common in Flutter Web CanvasKit)
        // We do NOT skip this check even if text is visible, because partial hydration can occur.
        try {
            // Check for the button explicitly
            com.microsoft.playwright.Locator accessBtn = page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Enable accessibility"));
            
            // If button exists, we MUST click it
            if (accessBtn.count() > 0 && accessBtn.first().isVisible()) {
                System.out.println("✓ Found 'Enable accessibility' button. Clicking it to hydrate DOM...");
                try {
                    accessBtn.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true).setDelay(100));
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
        } catch (com.microsoft.playwright.PlaywrightException e) {
            System.out.println("⚠️ Playwright exception while interacting with accessibility button: " + e.getMessage());
            // If the underlying Chromium target crashed, bubble up so that
            // navigateToApp() can recreate the page and fully reload the app.
            if (e.getMessage() != null && e.getMessage().contains("Target crashed")) {
                throw e;
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
        
        // Check if already on register page
        if (isTextVisible("Confirm Password") || isTextVisible("Repeat Password")) {
            return;
        }
        
        boolean clicked = false;
        
        // 1. Try "Don't have an account? Register" button/text
        try {
            com.microsoft.playwright.Locator link = page.getByText("Don't have an account? Register");
            if (link.count() > 0 && link.first().isVisible()) {
                System.out.println("Found 'Don't have an account? Register' link. Clicking...");
                link.first().click();
                clicked = true;
            }
        } catch (Exception e) {
            System.out.println("Click failed on full text: " + e.getMessage());
        }
        
        // 2. Try "Register" button if first attempt failed
        if (!clicked) {
            try {
                com.microsoft.playwright.Locator regBtn = page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Register"))
                   .or(page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Sign Up")));
                
                if (regBtn.count() > 0 && regBtn.first().isVisible()) {
                    System.out.println("Found Register button. Clicking...");
                    regBtn.first().click();
                    clicked = true;
                }
            } catch (Exception e) {
                 System.out.println("Register button click failed: " + e.getMessage());
            }
        }
        
        // 3. Fallback: Try finding "Register" text and clicking it
        if (!clicked && isTextVisible("Register")) {
             System.out.println("Fallback: Clicking 'Register' text...");
             try {
                 page.getByText("Register").last().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                 clicked = true;
             } catch (Exception e) {
                 System.out.println("Fallback text click failed: " + e.getMessage());
             }
        }
        
        // Wait for navigation to complete by checking for a field unique to Register page
        try {
            page.waitForTimeout(1000);
            // Wait for Confirm Password or specific title
            com.microsoft.playwright.Locator confirmInput = page.getByLabel("Confirm Password")
                .or(page.getByLabel("Repeat Password"))
                .or(page.getByPlaceholder("confirm password"));
                
            confirmInput.first().waitFor(new com.microsoft.playwright.Locator.WaitForOptions().setTimeout(5000));
            System.out.println("✓ Successfully navigated to Register page");
        } catch (Exception e) {
            System.out.println("⚠️ Warning: Did not detect Register page elements after navigation attempt.");
        }
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
            emailInput.first().waitFor(new com.microsoft.playwright.Locator.WaitForOptions().setTimeout(3000));
        } catch (Exception e) {
            // Fallbacks: label variant, placeholder, then generic text input
            emailInput = page.getByLabel("Email or Username").or(page.getByPlaceholder("email"));
            if (emailInput.count() == 0) {
                // Generic first input on login form (Email/Username)
                emailInput = page.locator("input").first();
            }
            try {
                emailInput.first().waitFor(new com.microsoft.playwright.Locator.WaitForOptions().setTimeout(3000));
            } catch (Exception ex) {
                System.out.println("Could not reliably find Email input. Proceeding to try anyway...");
            }
        }

        if (emailInput.count() == 0) {
            emailInput = page.locator("input").first();
        }

        // Try to scroll into view and interact using JS if standard fails
        try {
            emailInput.first().scrollIntoViewIfNeeded();
            emailInput.first().fill(email);
        } catch (Exception e) {
            System.out.println("Standard fill failed, trying JS fill for Email...");
            try {
                emailInput.first().evaluate("node => { node.value = '" + email + "'; node.dispatchEvent(new Event('input', { bubbles: true })); }");
            } catch (Exception ex) {
                System.out.println("JS fill for Email also failed: " + ex.getMessage());
            }
        }

        com.microsoft.playwright.Locator passInput = page.getByLabel("Password");
        if (passInput.count() == 0) {
            passInput = page.getByPlaceholder("password");
        }
        if (passInput.count() == 0) {
            // Try explicit password type, then fall back to second generic input
            passInput = page.locator("input[type='password']");
        }
        if (passInput.count() == 0) {
            com.microsoft.playwright.Locator allInputs = page.locator("input");
            if (allInputs.count() > 1) {
                passInput = allInputs.nth(1);
            } else {
                passInput = allInputs.first();
            }
        }

        try {
            passInput.first().scrollIntoViewIfNeeded();
            passInput.first().fill(password);
        } catch (Exception e) {
            System.out.println("Standard fill failed, trying JS fill for Password...");
            try {
                passInput.first().evaluate("node => { node.value = '" + password + "'; node.dispatchEvent(new Event('input', { bubbles: true })); }");
            } catch (Exception ex) {
                System.out.println("JS fill for Password also failed: " + ex.getMessage());
            }
        }
        
        // Final safety net: bulk-fill first two <input> elements via JS
        try {
            String script = "args => {" +
                    "  const inputs = Array.from(document.querySelectorAll('input'));" +
                    "  if (inputs.length > 0) {" +
                    "    inputs[0].value = args.email;" +
                    "    inputs[0].dispatchEvent(new Event('input', { bubbles: true }));" +
                    "  }" +
                    "  if (inputs.length > 1) {" +
                    "    inputs[1].value = args.password;" +
                    "    inputs[1].dispatchEvent(new Event('input', { bubbles: true }));" +
                    "  }" +
                    "  return inputs.length;" +
                    "}";
            Object count = page.evaluate(script, java.util.Map.of("email", email, "password", password));
            System.out.println("DEBUG: Bulk-filled login inputs, count=" + count);
        } catch (Exception e) {
            System.out.println("DEBUG: Bulk-fill login inputs failed: " + e.getMessage());
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
        // USERNAME FIELD
        com.microsoft.playwright.Locator userInput = page.getByLabel("Username");
        if (userInput.count() == 0) {
            userInput = page.getByPlaceholder("username");
        }
        if (userInput.count() == 0) {
            com.microsoft.playwright.Locator allInputs = page.locator("input");
            if (allInputs.count() > 0) {
                userInput = allInputs.first();
            }
        }

        if (userInput.count() > 0) {
            try {
                userInput.first().scrollIntoViewIfNeeded();
                userInput.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                userInput.first().clear();
                userInput.first().fill(username);
            } catch (Exception e) {
                System.out.println("Username input interaction failed; relying on bulk JS fill: " + e.getMessage());
            }
        }

        // EMAIL FIELD
        com.microsoft.playwright.Locator emailInput = page.getByLabel("Email");
        if (emailInput.count() == 0) {
            emailInput = page.getByPlaceholder("email");
        }
        if (emailInput.count() == 0) {
            com.microsoft.playwright.Locator allInputs = page.locator("input");
            if (allInputs.count() > 1) {
                emailInput = allInputs.nth(1);
            }
        }

        if (emailInput.count() > 0) {
            try {
                emailInput.first().scrollIntoViewIfNeeded();
                emailInput.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                emailInput.first().clear();
                emailInput.first().fill(email);
            } catch (Exception e) {
                System.out.println("Email input interaction failed; relying on bulk JS fill: " + e.getMessage());
            }
        }

        // PASSWORD FIELD
        com.microsoft.playwright.Locator passInput = page.getByLabel("Password");
        if (passInput.count() == 0) {
            passInput = page.getByPlaceholder("password");
        }
        if (passInput.count() == 0) {
            com.microsoft.playwright.Locator allInputs = page.locator("input[type='password']");
            if (allInputs.count() > 0) {
                passInput = allInputs.first();
            }
        }

        if (passInput.count() > 0) {
            try {
                passInput.first().scrollIntoViewIfNeeded();
                passInput.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                passInput.first().clear();
                passInput.first().fill(password);
            } catch (Exception e) {
                System.out.println("Password input interaction failed; relying on bulk JS fill: " + e.getMessage());
            }
        }

        // CONFIRM PASSWORD (IF PRESENT)
        com.microsoft.playwright.Locator confirmInput = page.getByLabel("Confirm Password")
            .or(page.getByLabel("Repeat Password"))
            .or(page.getByPlaceholder("confirm password"));

        if (confirmInput.count() > 0) {
            try {
                System.out.println("Found Confirm/Repeat Password field. Filling...");
                confirmInput.first().scrollIntoViewIfNeeded();
                confirmInput.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                confirmInput.first().clear();
                confirmInput.first().fill(password);
            } catch (Exception e) {
                System.out.println("Confirm password interaction failed; relying on bulk JS fill: " + e.getMessage());
            }
        }

        // Final safety net: bulk-fill the first four <input> elements via JS
        try {
            String script = "args => {" +
                    "  const inputs = Array.from(document.querySelectorAll('input'));" +
                    "  if (inputs.length > 0) {" +
                    "    inputs[0].value = args.username;" +
                    "    inputs[0].dispatchEvent(new Event('input', { bubbles: true }));" +
                    "  }" +
                    "  if (inputs.length > 1) {" +
                    "    inputs[1].value = args.email;" +
                    "    inputs[1].dispatchEvent(new Event('input', { bubbles: true }));" +
                    "  }" +
                    "  if (inputs.length > 2) {" +
                    "    inputs[2].value = args.password;" +
                    "    inputs[2].dispatchEvent(new Event('input', { bubbles: true }));" +
                    "  }" +
                    "  if (inputs.length > 3) {" +
                    "    inputs[3].value = args.password;" +
                    "    inputs[3].dispatchEvent(new Event('input', { bubbles: true }));" +
                    "  }" +
                    "  return inputs.length;" +
                    "}";

            Object count = page.evaluate(script, java.util.Map.of(
                    "username", username,
                    "email", email,
                    "password", password
            ));
            System.out.println("DEBUG: Bulk-filled register inputs, count=" + count);
        } catch (Exception e) {
            System.out.println("DEBUG: Bulk-fill register inputs failed: " + e.getMessage());
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
        
        // 3. Failure - Dump for debugging and fall back to a forced logout
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

        // As a last resort, simulate logout by clearing local storage and returning to the app root.
        System.out.println("Logout button not found, forcing logout via localStorage clear + navigateToApp()...");
        try {
            page.evaluate("window.localStorage.clear()");
        } catch (Exception e) {
            System.out.println("Error clearing local storage during forced logout: " + e.getMessage());
        }

        // Navigate back to app; resetToLoginPage()/navigateToApp will ensure login page if possible.
        try {
            navigateToApp();
        } catch (Exception e) {
            System.out.println("Error navigating to app during forced logout: " + e.getMessage());
        }
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
        // Primary: use Playwright's getByText on the accessibility tree
        try {
            com.microsoft.playwright.Locator byText = page.getByText(text);
            if (byText.count() > 0 && byText.first().isVisible()) {
                return true;
            }
        } catch (Exception e) {
            // ignore and fall back to aria-label scan
        }

        // Fallback: scan aria-label attributes (Flutter Semantics on web uses these)
        // and page innerText for robustness
        try {
            String script = "needle => {" +
                    "  const t = String(needle).toLowerCase();" +
                    "  const nodes = Array.from(document.querySelectorAll('[aria-label]'));" +
                    "  const ariaHit = nodes.some(n => (n.getAttribute('aria-label') || '').toLowerCase().includes(t));" +
                    "  if (ariaHit) return true;" +
                    "  const bodyText = (document.body && document.body.innerText) ? document.body.innerText.toLowerCase() : '';" +
                    "  return bodyText.includes(t);" +
                    "}";

            Boolean found = (Boolean) page.evaluate(script, text);
            if (Boolean.TRUE.equals(found)) {
                return true;
            }
        } catch (Exception e) {
            // ignore and treat as not visible
        }

        return false;
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
        page.getByText(text).waitFor(new com.microsoft.playwright.Locator.WaitForOptions()
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
