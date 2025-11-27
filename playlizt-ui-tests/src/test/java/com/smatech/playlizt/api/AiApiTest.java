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
public class AiApiTest {

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
    public void testGetRecommendations() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .param("userId", 1)
                .when()
                .get("/ai/recommendations")
                .then()
                .statusCode(200)
                .body("$", notNullValue()) // Should return list
                .body("size()", greaterThanOrEqualTo(0));
    }
}
