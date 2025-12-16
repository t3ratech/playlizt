package zw.co.t3ratech.playlizt.api;

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
public class PlaybackApiTest extends BaseApiTest {

    private static Long contentId;

    @BeforeAll
    public static void setup() {
        // Base setup (login, properties) handled by BaseApiTest
        
        // Add Content
        contentId = addContent("Playback Test Video");
        publishContent(contentId);
    }

    private static Long addContent(String title) {
        String body = String.format("{" +
                "\"title\": \"%s\"," +
                "\"description\": \"Caught up in a way Licoflat ft. Tich de Blak\"," +
                "\"category\": \"Hip Hip\"," +
                "\"creatorId\": 1," +
                "\"videoUrl\": \"https://www.youtube.com/watch?v=GEeMjb0dd5U\"," +
                "\"thumbnailUrl\": \"https://d3e6ckxkrs5ntg.cloudfront.net/artists/images/316898/original/resize:740x600/crop:x0y14w444h333/aspect:1.0/hash:1466574974/Blaklizt_Logo_Final.jpg?1466574974\"," +
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
