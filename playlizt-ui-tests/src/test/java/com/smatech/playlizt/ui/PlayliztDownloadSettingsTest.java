package zw.co.t3ratech.playlizt.ui;

import com.microsoft.playwright.Page;
import com.microsoft.playwright.options.AriaRole;
import org.junit.jupiter.api.*;

import static org.assertj.core.api.Assertions.*;

/**
 * Validates the Download tab UI and the Settings drawer sections
 * related to downloads and library configuration.
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztDownloadSettingsTest extends BasePlayliztTest {

    @Test
    @Order(1)
    @DisplayName("01 - Download: Tab UI and empty queue state")
    void test01_DownloadTabUi() {
        navigateToApp();

        if (isTextVisible("Login")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
            page.waitForTimeout(2000);
        }

        clickTabByLabel("Download");
        page.waitForTimeout(1500);

        takeScreenshot("download", "01_tab_ui", "01_download_tab.png");

        assertTextVisible(
                "Download from URL",
                "Download tab header must be visible after selecting Download tab"
        );
        assertTextVisible(
                "Use default download location",
                "Download tab must show default download location toggle"
        );
        assertTextVisible(
                "No downloads yet",
                "Download queue should show empty state when there are no downloads"
        );
    }

    @Test
    @Order(2)
    @DisplayName("02 - Settings: Download configuration in Settings drawer")
    void test02_SettingsDrawerDownloadSection() {
        navigateToApp();

        if (isTextVisible("Login")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
            page.waitForTimeout(2000);
        }

        openSettingsDrawer();
        page.waitForTimeout(1000);

        takeScreenshot("settings", "01_download_section", "01_drawer_open.png");

        assertTextVisible("Settings", "Settings drawer title should be visible");
        assertTextVisible("Default download folder", "Settings drawer should show default download folder");
        assertTextVisible("Library scan folders", "Settings drawer should show library scan folders section");
        assertTextVisible("Startup tab", "Settings drawer should show startup tab configuration");
    }

    private void clickTabByLabel(String label) {
        // 1. Try text-based locator (bottom nav label or navigation rail label)
        try {
            com.microsoft.playwright.Locator tab = page.getByText(label);
            if (tab.count() > 0 && tab.first().isVisible()) {
                tab.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
                return;
            }
        } catch (Exception e) {
            System.out.println("Primary tab click by text failed for '" + label + "': " + e.getMessage());
        }

        // 2. Fallback to aria-label semantics (Flutter assigns labels to nav items)
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

        takeScreenshot("failures", "download_tab",
                "missing_tab_" + label.replaceAll("\\s+", "_") + ".png");
        fail("Unable to locate shell tab with label '" + label + "'");
    }
}
