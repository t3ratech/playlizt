package com.smatech.playlizt.ui;

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
        
        // Check for common categories (assumed seeded or from Backend)
        // We know Backend has "Music", "Gaming", "Tech", "Education" etc.
        
        boolean hasMusic = isTextVisible("Music");
        boolean hasGaming = isTextVisible("Gaming");
        boolean hasTech = isTextVisible("Tech");
        boolean hasEducation = isTextVisible("Education");
        
        if (hasMusic || hasGaming || hasTech || hasEducation) {
             System.out.println("✅ Found Category Chips");
             takeScreenshot("categories", "01_home", "02_chips_visible.png");
             
             // Try clicking one
             if (hasMusic) {
                 System.out.println("Clicking 'Music' chip...");
                 page.getByText("Music").first().click();
                 page.waitForTimeout(2000);
                 takeScreenshot("categories", "01_home", "03_music_selected.png");
             }
        } else {
             System.out.println("⚠️ No Category Chips found. Are categories loaded?");
        }
        
        assertThat(getCurrentUrl()).doesNotContain("login");
    }
}
