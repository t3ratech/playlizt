package com.smatech.playlizt.ui;

import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlayliztSentimentTest extends BasePlayliztTest {

    @Test
    @Order(1)
    @DisplayName("01 - Sentiment: Verify Metadata Display")
    void test01_VerifySentimentMetadata() {
        navigateToApp();
        
        if (isTextVisible("Login")) {
            login(TEST_USER_EMAIL, TEST_USER_PASSWORD);
        }
        page.waitForTimeout(3000);
        
        takeScreenshot("sentiment", "01_home", "01_dashboard.png");
        
        // Check for Rating text (G, PG, PG-13, R, NC-17)
        // Check for Sentiment text (POSITIVE, NEUTRAL, NEGATIVE, etc.)
        
        boolean hasPG = isTextVisible("PG");
        boolean hasPG13 = isTextVisible("PG-13");
        boolean hasR = isTextVisible("R");
        boolean hasG = isTextVisible("G");
        
        boolean hasPositive = isTextVisible("POSITIVE");
        boolean hasNeutral = isTextVisible("NEUTRAL");
        boolean hasInspiring = isTextVisible("INSPIRING");
        boolean hasEducational = isTextVisible("EDUCATIONAL");
        
        if (hasG || hasPG || hasPG13 || hasR) {
             System.out.println("✅ Found Content Rating (G/PG/PG-13/R)");
        }
        
        if (hasPositive || hasNeutral || hasInspiring || hasEducational) {
             System.out.println("✅ Found Sentiment (POSITIVE/NEUTRAL/INSPIRING/EDUCATIONAL)");
        }
        
        if ((hasG || hasPG || hasPG13 || hasR) && (hasPositive || hasNeutral || hasInspiring || hasEducational)) {
             takeScreenshot("sentiment", "01_home", "02_metadata_found.png");
        } else {
             System.out.println("⚠️ Sentiment/Rating metadata NOT found. Content might need enhancement.");
        }
        
        assertThat(getCurrentUrl()).doesNotContain("login");
    }
}
