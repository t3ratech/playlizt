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
public class ContentApiTest extends BaseApiTest {

    private static Long contentId;

    @Test
    @Order(1)
    public void testCreateContent() {
        String contentBody = "{" +
                "\"title\": \"E2E Test Video\"," +
                "\"description\": \"Created via API E2E Test\"," +
                "\"category\": \"TEST\"," +
                "\"creatorId\": 1," +
                "\"videoUrl\": \"https://www.youtube.com/watch?v=dQw4w9WgXcQ\"," +
                "\"thumbnailUrl\": \"https://example.com/thumb.jpg\"," +
                "\"tags\": [\"test\", \"e2e\"]," +
                "\"durationSeconds\": 120" +
                "}";

        Response response = given()
                .header("Authorization", "Bearer " + authToken)
                .contentType(ContentType.JSON)
                .body(contentBody)
                .when()
                .post("/content")
                .then()
                .statusCode(201)
                .body("title", equalTo("E2E Test Video"))
                .extract().response();

        contentId = response.path("id").toString() != null ? Long.parseLong(response.path("id").toString()) : null;
        System.out.println("Created Content ID: " + contentId);
    }

    @Test
    @Order(2)
    public void testGetContent() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/content/" + contentId)
                .then()
                .statusCode(200)
                .body("id", equalTo(contentId.intValue()))
                .body("title", equalTo("E2E Test Video"));
    }

    @Test
    @Order(3)
    public void testUpdateContent() {
        String updateBody = "{" +
                "\"title\": \"Updated E2E Video\"," +
                "\"description\": \"Updated Description\"," +
                "\"category\": \"TEST\"," +
                "\"creatorId\": 1," +
                "\"videoUrl\": \"https://www.youtube.com/watch?v=dQw4w9WgXcQ\"," +
                "\"thumbnailUrl\": \"https://example.com/thumb.jpg\"," +
                "\"tags\": [\"test\", \"updated\"]," +
                "\"durationSeconds\": 120" +
                "}";

        given()
                .header("Authorization", "Bearer " + authToken)
                .contentType(ContentType.JSON)
                .body(updateBody)
                .when()
                .put("/content/" + contentId)
                .then()
                .statusCode(200)
                .body("title", equalTo("Updated E2E Video"));
    }

    @Test
    @Order(4)
    public void testIncrementViewCount() {
        // Get current view count
        int initialViews = given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/content/" + contentId)
                .then()
                .statusCode(200)
                .extract().jsonPath().getInt("viewCount");

        // Increment
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .post("/content/" + contentId + "/view")
                .then()
                .statusCode(200);

        // Verify increase
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/content/" + contentId)
                .then()
                .statusCode(200)
                .body("viewCount", equalTo(initialViews + 1));
    }

    @Test
    @Order(5)
    public void testDeleteContent() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .delete("/content/" + contentId)
                .then()
                .statusCode(204);

        // Verify deletion
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/content/" + contentId)
                .then()
                .statusCode(anyOf(equalTo(404), equalTo(500)))
                .log().ifValidationFails();
    }
}
