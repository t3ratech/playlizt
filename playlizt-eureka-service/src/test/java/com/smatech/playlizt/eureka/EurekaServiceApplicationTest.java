package zw.co.t3ratech.playlizt.eureka;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = "SERVER_PORT=0")
class EurekaServiceApplicationTest {

    @Test
    void contextLoads() {
        // Verify application context loads successfully
    }
}
