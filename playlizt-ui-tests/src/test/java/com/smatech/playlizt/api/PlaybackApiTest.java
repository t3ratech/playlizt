package com.smatech.playlizt.api;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class PlaybackApiTest {

    private static String authToken;
    private static Long contentId;
    private static final String BASE_URL = "http://localhost:4080/api/v1";

    @BeforeAll
    public static void setup() {
        RestAssured.baseURI = BASE_URL;
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();
        
        // Login
        String loginBody = "{ \"email\": \"tkaviya@t3ratech.co.zw\", \"password\": \"testpass\" }";
        
        Response response = given()
                .contentType(ContentType.JSON)
                .body(loginBody)
                .when()
                .post("/auth/login")
                .then()
                .statusCode(200)
                .extract().response();
                
        authToken = response.path("data.token");
        
        // Create Content
        contentId = createContent("Playback Test Video");
        publishContent(contentId);
    }

    private static Long createContent(String title) {
        String body = String.format("{" +
                "\"title\": \"%s\"," +
                "\"description\": \"Testing Playback\"," +
                "\"category\": \"Test\"," +
                "\"creatorId\": 1," +
                "\"videoUrl\": \"http://example.com/vid\"," +
                "\"thumbnailUrl\": \"http://example.com/thumb\"," +
                "\"tags\": [\"playback\"]," +
                "\"durationSeconds\": 300" +
                "}", title);

        return given()
                .header("Authorization", "Bearer " + authToken)
                .contentType(ContentType.JSON)
                .body(body)
                .when()
                .post("/content")
                .then()
                .statusCode(201)
                .extract().jsonPath().getLong("id");
    }
    
    private static void publishContent(Long id) {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .post("/content/" + id + "/publish")
                .then()
                .statusCode(200);
    }

    @Test
    @Order(1)
    public void testTrackPlaybackStart() {
        String body = "{" +
                "\"contentId\": " + contentId + "," +
                "\"userId\": 1," +
                "\"positionSeconds\": 10" +
                "}";

        given()
                .header("Authorization", "Bearer " + authToken)
                .contentType(ContentType.JSON)
                .body(body)
                .when()
                .post("/playback/track")
                .then()
                .statusCode(200)
                .body("lastPositionSeconds", equalTo(10));
    }

    @Test
    @Order(2)
    public void testTrackPlaybackUpdate() {
        String body = "{" +
                "\"contentId\": " + contentId + "," +
                "\"userId\": 1," +
                "\"positionSeconds\": 20" +
                "}";

        given()
                .header("Authorization", "Bearer " + authToken)
                .contentType(ContentType.JSON)
                .body(body)
                .when()
                .post("/playback/track")
                .then()
                .statusCode(200)
                .body("lastPositionSeconds", equalTo(20))
                .body("watchTimeSeconds", greaterThan(0)); // Should have increased
    }

    @Test
    @Order(3)
    public void testGetHistory() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .param("userId", 1)
                .when()
                .get("/playback/history")
                .then()
                .statusCode(200)
                .body("content.contentId", hasItem(contentId.intValue()));
    }

    @Test
    @Order(4)
    public void testContinueWatching() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .param("userId", 1)
                .when()
                .get("/playback/continue")
                .then()
                .statusCode(200)
                .body("content.contentId", hasItem(contentId.intValue()))
                .body("content.completed", hasItem(false));
    }
    
    @Test
    @Order(5)
    public void testCompletePlayback() {
        String body = "{" +
                "\"contentId\": " + contentId + "," +
                "\"userId\": 1," +
                "\"positionSeconds\": 300," +
                "\"completed\": true" +
                "}";

        given()
                .header("Authorization", "Bearer " + authToken)
                .contentType(ContentType.JSON)
                .body(body)
                .when()
                .post("/playback/track")
                .then()
                .statusCode(200)
                .body("completed", equalTo(true));
    }

    @Test
    @Order(6)
    public void testAnalytics() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/playback/analytics/content/" + contentId)
                .then()
                .statusCode(200)
                .body("uniqueViewers", greaterThanOrEqualTo(1))
                .body("totalWatchTimeSeconds", greaterThanOrEqualTo(0));
    }

    @Test
    @Order(7)
    public void testPlatformAnalytics() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/playback/analytics/platform")
                .then()
                .statusCode(200)
                .body("totalSessions", greaterThanOrEqualTo(1))
                .body("totalWatchTimeSeconds", greaterThanOrEqualTo(0));
    }
}
