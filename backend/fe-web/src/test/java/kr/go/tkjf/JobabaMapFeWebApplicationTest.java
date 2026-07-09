package kr.go.tkjf;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "JOBABA_MAP_API_BASE_URL="
)
class JobabaMapFeWebApplicationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void mapPageRendersJsp() {
        ResponseEntity<String> response = restTemplate.getForEntity("/map", String.class);

        assertThat(response.getStatusCodeValue()).isEqualTo(200);
        assertThat(response.getBody()).contains("window.JobabaMapConfig");
    }
}
