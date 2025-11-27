package com.smatech.playlizt.api;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class UploadApiTest {

    private static String authToken;
    private static String fileUrl;
    private static String fileName;
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
    public void testUploadFile() throws IOException {
        // Create dummy file
        File file = File.createTempFile("test-video", ".mp4");
        Files.write(file.toPath(), "dummy video content".getBytes());

        Response response = given()
                .header("Authorization", "Bearer " + authToken)
                .multiPart("file", file)
                .when()
                .post("/content/upload")
                .then()
                .statusCode(200)
                .body("url", notNullValue())
                .body("fileName", notNullValue())
                .extract().response();

        fileUrl = response.path("url");
        fileName = response.path("fileName");
        
        System.out.println("Uploaded file URL: " + fileUrl);
        
        file.delete();
    }

    @Test
    @Order(2)
    public void testDownloadFile() {
        // fileUrl is like /api/v1/content/files/{uuid}.mp4
        // RestAssured baseURI is /api/v1
        // We need to extract path relative to baseURI
        
        String path = fileUrl.replace("/api/v1", "");
        
        byte[] content = given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get(path)
                .then()
                .statusCode(200)
                .extract().asByteArray();
                
        String contentStr = new String(content);
        if (!contentStr.equals("dummy video content")) {
            throw new AssertionError("Content mismatch: " + contentStr);
        }
    }
}
