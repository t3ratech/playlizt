package com.smatech.playlizt.api;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
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
            if (is == null) {
                throw new RuntimeException("test.properties not found in classpath");
            }
            props.load(is);
            
            // Load port from .env
            String apiPort = loadEnvPort();
            baseUrl = "http://localhost:" + apiPort + "/api/v1";
            
            // Load user credentials from properties - NO HARDCODED DEFAULTS
            testUserEmail = props.getProperty("test.user.email");
            testUserPassword = props.getProperty("test.user.password");
            
            if (testUserEmail == null || testUserPassword == null) {
                throw new RuntimeException("test.user.email and test.user.password must be set in test.properties");
            }
            
        } catch (IOException e) {
            throw new RuntimeException("Failed to load test configuration: " + e.getMessage(), e);
        }
    }

    private static String loadEnvPort() {
        // Try to find .env file in project root or parent directories
        File currentDir = new File(System.getProperty("user.dir"));
        File envFile = null;
        
        while (currentDir != null) {
            File candidate = new File(currentDir, ".env");
            if (candidate.exists()) {
                envFile = candidate;
                break;
            }
            currentDir = currentDir.getParentFile();
        }
        
        if (envFile == null || !envFile.exists()) {
             // Fallback to checking environment variable if .env file not found
             String envPort = System.getenv("PLAYLIZT_API_GATEWAY_PORT");
             if (envPort == null) {
                 envPort = System.getenv("API_GATEWAY_PORT");
             }
             if (envPort != null) return envPort;
             throw new RuntimeException(".env file not found and PLAYLIZT_API_GATEWAY_PORT/API_GATEWAY_PORT environment variable not set");
        }

        try (BufferedReader reader = new BufferedReader(new FileReader(envFile))) {
            String line;
            while ((line = reader.readLine()) != null) {
                String trimmed = line.trim();
                if (trimmed.startsWith("PLAYLIZT_API_GATEWAY_PORT=")) {
                    return trimmed.split("=")[1].trim();
                }
                if (trimmed.startsWith("API_GATEWAY_PORT=")) {
                    return trimmed.split("=")[1].trim();
                }
            }
        } catch (IOException e) {
            throw new RuntimeException("Error reading .env file", e);
        }
        
        throw new RuntimeException("PLAYLIZT_API_GATEWAY_PORT/API_GATEWAY_PORT not found in .env file");
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
