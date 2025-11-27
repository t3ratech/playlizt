package com.smatech.playlizt.api;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

import static io.restassured.RestAssured.given;

public abstract class BaseApiTest {

    protected static String authToken;
    protected static String baseUrl;
    protected static String testUserEmail;
    protected static String testUserPassword;

    @BeforeAll
    public static void setupBase() {
        loadProperties();
        RestAssured.baseURI = baseUrl;
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();
        
        if (authToken == null) {
            login();
        }
    }

    private static void loadProperties() {
        Properties props = new Properties();
        try (InputStream is = BaseApiTest.class.getClassLoader().getResourceAsStream("test.properties")) {
            if (is != null) {
                props.load(is);
                // Fallback to system properties if set, otherwise use properties file
                baseUrl = System.getProperty("test.api.url", props.getProperty("test.api.url", "http://localhost:4080/api/v1"));
                testUserEmail = System.getProperty("test.user.email", props.getProperty("test.user.email", "tkaviya@t3ratech.co.zw"));
                testUserPassword = System.getProperty("test.user.password", props.getProperty("test.user.password", "testpass"));
            } else {
                // Default fallbacks if file missing
                baseUrl = System.getProperty("test.api.url", "http://localhost:4080/api/v1");
                testUserEmail = System.getProperty("test.user.email", "tkaviya@t3ratech.co.zw");
                testUserPassword = System.getProperty("test.user.password", "testpass");
            }
        } catch (IOException e) {
            System.err.println("Could not load test.properties: " + e.getMessage());
            baseUrl = "http://localhost:4080/api/v1";
            testUserEmail = "tkaviya@t3ratech.co.zw";
            testUserPassword = "testpass";
        }
    }

    private static void login() {
        String loginBody = String.format("{ \"email\": \"%s\", \"password\": \"%s\" }", testUserEmail, testUserPassword);

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
}
