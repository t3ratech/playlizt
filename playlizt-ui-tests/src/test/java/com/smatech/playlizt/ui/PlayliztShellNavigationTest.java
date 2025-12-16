package zw.co.t3ratech.playlizt.ui;

import com.microsoft.playwright.Page;
import com.microsoft.playwright.options.AriaRole;
import org.junit.jupiter.api.*;

import static org.assertj.core.api.Assertions.*;

/**
 * Verifies the global multimedia shell navigation: Library / Playlists /
 * Streaming / Download / Convert / Devices.
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztShellNavigationTest extends BasePlayliztTest {

    @Test
    @Order(1)
    @DisplayName("01 - Shell: Login and verify Streaming as default tab")
    void test01_LoginAndStreamingDefault() {
        navigateToApp();

        if (isTextVisible("Login")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
            page.waitForTimeout(3000);
        }

        takeScreenshot("shell", "01_streaming_default", "01_after_login.png");

        assertThat(getCurrentUrl()).doesNotContain("login");
        // Streaming tab should expose the main content grid
        assertTextVisible(
                "Browse Content",
                "Streaming dashboard (Browse Content) should be visible after login"
        );
    }

    @Test
    @Order(2)
    @DisplayName("02 - Shell: Switch between main tabs (Playlists, Streaming, Download, Convert) on web")
    void test02_SwitchTabs() {
        navigateToApp();

        // Ensure we are authenticated
        if (isTextVisible("Login")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
            page.waitForTimeout(2000);
        }

        // 1. Playlists tab (Library tab is not available on Flutter web)
        clickTabByLabel("Playlists");
        page.waitForTimeout(1000);
        takeScreenshot("shell", "02_navigation", "01_playlists.png");
        assertTextVisible(
                "Playlists",
                "Playlists header should be visible after selecting Playlists tab"
        );

        // 2. Streaming tab
        clickTabByLabel("Streaming");
        page.waitForTimeout(1000);
        takeScreenshot("shell", "02_navigation", "02_streaming.png");
        assertTextVisible(
                "Browse Content",
                "Streaming content grid should be visible after selecting Streaming tab"
        );

        // 3. Download tab
        clickTabByLabel("Download");
        page.waitForTimeout(1000);
        takeScreenshot("shell", "02_navigation", "03_download.png");
        assertTextVisible(
                "Download from URL",
                "Download tab header should be visible after selecting Download tab"
        );

        // 4. Convert tab
        clickTabByLabel("Convert");
        page.waitForTimeout(1000);
        takeScreenshot("shell", "02_navigation", "04_convert.png");
        assertTextVisible(
                "Convert Media",
                "Convert tab header should be visible after selecting Convert tab"
        );
    }

    /**
     * Click a shell tab by its label using robust Flutter web friendly locators.
     */
    private void clickTabByLabel(String label) {
        waitForTabBridge();

        // 0. Preferred path for Flutter Web: use JS bridge exposed by app.
        try {
            String script = "label => {" +
                    "  if (typeof window !== 'undefined' && typeof window.playliztNavigateToTab === 'function') {" +
                    "    const map = { 'Library':0, 'Playlists':1, 'Streaming':2, 'Download':3, 'Convert':4, 'Devices':5 };" +
                    "    const idx = map[label];" +
                    "    if (typeof idx === 'number') {" +
                    "      window.playliztNavigateToTab(idx);" +
                    "      return true;" +
                    "    }" +
                    "  }" +
                    "  return false;" +
                    "}";
            Object usedBridge = page.evaluate(script, label);
            if (usedBridge instanceof Boolean && (Boolean) usedBridge) {
                page.waitForTimeout(500);
                return;
            }
        } catch (Exception e) {
            System.out.println("Tab JS bridge navigation failed for '" + label + "': " + e.getMessage());
        }

        // 1. Try text-based locator (navigation rail label semantics)
        try {
            com.microsoft.playwright.Locator tab = page.getByText(label);
            if (tab.count() > 0 && tab.first().isVisible()) {
                tab.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                return;
            }
        } catch (Exception e) {
            System.out.println("Primary tab click by text failed for '" + label + "': " + e.getMessage());
        }

        // 2. Fallback to aria-label semantics (if available)
        try {
            com.microsoft.playwright.Locator ariaTab = page
                    .locator("[aria-label*='" + label + "']")
                    .first();
            if (ariaTab != null && ariaTab.count() > 0 && ariaTab.isVisible()) {
                ariaTab.click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                return;
            }
        } catch (Exception e) {
            System.out.println("Fallback tab click by aria-label failed for '" + label + "': " + e.getMessage());
        }

        takeScreenshot("failures", "shell_navigation",
                "missing_tab_" + label.replaceAll("\\s+", "_") + ".png");
        fail("Unable to locate shell tab with label '" + label + "'");
    }

    private void waitForTabBridge() {
        try {
            for (int i = 0; i < 30; i++) {
                Object ok = page.evaluate("() => typeof window !== 'undefined' && typeof window.playliztNavigateToTab === 'function'");
                if (ok instanceof Boolean && (Boolean) ok) {
                    return;
                }
                page.waitForTimeout(200);
            }
        } catch (Exception ignored) {
        }
    }
}
