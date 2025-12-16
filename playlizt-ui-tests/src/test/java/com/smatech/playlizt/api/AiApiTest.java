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
public class AiApiTest extends BaseApiTest {

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
