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
public class SearchApiTest {

    private static String authToken;
    private static final String BASE_URL = "http://localhost:4080/api/v1";

    @BeforeAll
    public static void setup() {
        RestAssured.baseURI = BASE_URL;
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();
        
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
    }

    @Test
    @Order(1)
    public void setupContent() {
        // Create content with specific attributes for filtering
        // Note: Need to publish content for it to be searchable by default (searchContent usually filters published=true)
        // ContentService.createContent sets published=false.
        // I need to publish them.
        
        Long id1 = createContent("Action Movie", "Fast paced", "Action", 120);
        publishContent(id1);
        
        Long id2 = createContent("Drama Movie", "Slow paced", "Drama", 60);
        publishContent(id2);
        
        Long id3 = createContent("Short Clip", "Very short", "Clips", 30);
        publishContent(id3);
    }

    private Long createContent(String title, String desc, String category, int duration) {
        String body = String.format("{" +
                "\"title\": \"%s\"," +
                "\"description\": \"%s\"," +
                "\"category\": \"%s\"," +
                "\"creatorId\": 1," +
                "\"videoUrl\": \"http://example.com/vid\"," +
                "\"thumbnailUrl\": \"http://example.com/thumb\"," +
                "\"tags\": [\"test\"]," +
                "\"durationSeconds\": %d" +
                "}", title, desc, category, duration);

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
    
    private void publishContent(Long id) {
        if (id == null) return; // Should assertion fail before
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .post("/content/" + id + "/publish")
                .then()
                .statusCode(200);
    }

    @Test
    @Order(2)
    public void testSearchByQuery() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .param("q", "Action")
                .when()
                .get("/content/search")
                .then()
                .statusCode(200)
                .body("content.title", hasItem("Action Movie"))
                .body("content.size()", greaterThanOrEqualTo(1));
    }

    @Test
    @Order(3)
    public void testSearchByCategory() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .param("category", "Drama")
                .when()
                .get("/content/search")
                .then()
                .statusCode(200)
                .body("content.title", hasItem("Drama Movie"))
                .body("content.title", not(hasItem("Action Movie")));
    }

    @Test
    @Order(4)
    public void testSearchByDuration() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .param("maxDuration", 40)
                .when()
                .get("/content/search")
                .then()
                .statusCode(200)
                .body("content.title", hasItem("Short Clip"))
                .body("content.title", not(hasItem("Action Movie")));
    }
}
