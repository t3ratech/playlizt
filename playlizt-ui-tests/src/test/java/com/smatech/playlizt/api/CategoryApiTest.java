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
public class CategoryApiTest extends BaseApiTest {

    private static Long categoryId;

    @Test
    @Order(1)
    public void testCreateCategory() {
        String categoryBody = "{" +
                "\"name\": \"Action\"," +
                "\"description\": \"Action Movies\"" +
                "}";

        Response response = given()
                .header("Authorization", "Bearer " + authToken)
                .contentType(ContentType.JSON)
                .body(categoryBody)
                .when()
                .post("/categories")
                .then()
                .statusCode(201)
                .body("name", equalTo("Action"))
                .extract().response();

        categoryId = response.path("id").toString() != null ? Long.parseLong(response.path("id").toString()) : null;
    }

    @Test
    @Order(2)
    public void testGetCategory() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/categories/" + categoryId)
                .then()
                .statusCode(200)
                .body("name", equalTo("Action"));
    }
    
    @Test
    @Order(3)
    public void testUpdateCategory() {
        String updateBody = "{" +
                "\"name\": \"Action Thriller\"," +
                "\"description\": \"Action and Thriller Movies\"" +
                "}";

        given()
                .header("Authorization", "Bearer " + authToken)
                .contentType(ContentType.JSON)
                .body(updateBody)
                .when()
                .put("/categories/" + categoryId)
                .then()
                .statusCode(200)
                .body("name", equalTo("Action Thriller"));
    }
    
    @Test
    @Order(4)
    public void testListCategories() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/categories")
                .then()
                .statusCode(200)
                .body("size()", greaterThan(0))
                .body("name", hasItem("Action Thriller"));
    }

    @Test
    @Order(5)
    public void testDeleteCategory() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .delete("/categories/" + categoryId)
                .then()
                .statusCode(204);
                
        // Verify deletion (expecting error)
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/categories/" + categoryId)
                .then()
                .statusCode(anyOf(equalTo(404), equalTo(500)));
    }
}
