package zw.co.t3ratech.playlizt.ui;

import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztCategoryTest extends BasePlayliztTest {

    @Test
    @Order(1)
    @DisplayName("01 - Categories: Verify Chips Visible")
    void test01_VerifyCategoryChips() {
        navigateToApp();
        
        if (isTextVisible("Login")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
        }
        page.waitForTimeout(3000);
        
        takeScreenshot("categories", "01_home", "01_dashboard.png");
        
        // Categories are sourced from published content categories.
        boolean hasEntertainment = isTextVisible("ENTERTAINMENT");

        if (hasEntertainment) {
            takeScreenshot("categories", "01_home", "02_chips_visible.png");

            com.microsoft.playwright.Locator chip = page.locator("[aria-label='ENTERTAINMENT']");
            if (chip.count() > 0 && chip.first().isVisible()) {
                chip.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
            } else {
                page.getByText(
                                "ENTERTAINMENT",
                                new com.microsoft.playwright.Page.GetByTextOptions().setExact(true))
                        .first()
                        .click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
            }
            page.waitForTimeout(2000);
            takeScreenshot("categories", "01_home", "03_entertainment_selected.png");
        } else {
            takeScreenshot("categories", "01_home", "02_chips_missing.png");
            if (isTextVisible("Network error") ||
                    consoleContains("Network error. Please check your connection.") ||
                    consoleContains("ERR_CONNECTION_REFUSED")) {
                fail("No Category Chips visible due to network/gateway error; environment is not healthy.");
            }
            fail("No Category Chips visible on dashboard.");
        }
        
        assertThat(getCurrentUrl()).doesNotContain("login");
    }
}
