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
public class TagApiTest extends BaseApiTest {

    private static Long tagId;

    @Test
    @Order(1)
    public void testCreateTag() {
        String tagBody = "{\"name\": \"NewTag\"}";

        Response response = given()
                .header("Authorization", "Bearer " + authToken)
                .contentType(ContentType.JSON)
                .body(tagBody)
                .when()
                .post("/tags")
                .then()
                .statusCode(201)
                .body("name", equalTo("NewTag"))
                .extract().response();

        tagId = response.path("id").toString() != null ? Long.parseLong(response.path("id").toString()) : null;
    }

    @Test
    @Order(2)
    public void testGetTag() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/tags/" + tagId)
                .then()
                .statusCode(200)
                .body("name", equalTo("NewTag"));
    }
    
    @Test
    @Order(3)
    public void testUpdateTag() {
        String updateBody = "{\"name\": \"UpdatedTag\"}";

        given()
                .header("Authorization", "Bearer " + authToken)
                .contentType(ContentType.JSON)
                .body(updateBody)
                .when()
                .put("/tags/" + tagId)
                .then()
                .statusCode(200)
                .body("name", equalTo("UpdatedTag"));
    }
    
    @Test
    @Order(4)
    public void testListTags() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/tags")
                .then()
                .statusCode(200)
                .body("size()", greaterThan(0))
                .body("name", hasItem("UpdatedTag"));
    }

    @Test
    @Order(5)
    public void testDeleteTag() {
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .delete("/tags/" + tagId)
                .then()
                .statusCode(204);
                
        given()
                .header("Authorization", "Bearer " + authToken)
                .when()
                .get("/tags/" + tagId)
                .then()
                .statusCode(anyOf(equalTo(404), equalTo(500)));
    }
}
