package kr.go.tkjf.usr.map.controller;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpHeaders.ORIGIN;
import static org.springframework.http.HttpHeaders.REFERER;

class MapOriginPolicyTest {

    private final MapOriginPolicy policy = new MapOriginPolicy(Collections.singletonList("http://localhost:8080"));

    @Test
    void allowsConfiguredFeWebOriginForAjaxWrite() {
        MockHttpServletRequest request = writeRequest();
        request.addHeader(ORIGIN, "http://localhost:8080");

        assertThat(policy.isAllowedWrite(request)).isTrue();
    }

    @Test
    void rejectsUntrustedOriginForAjaxWrite() {
        MockHttpServletRequest request = writeRequest();
        request.addHeader(ORIGIN, "https://evil.example");

        assertThat(policy.isAllowedWrite(request)).isFalse();
    }

    @Test
    void allowsSameOriginRefererForAjaxWrite() {
        MockHttpServletRequest request = writeRequest();
        request.addHeader(REFERER, "http://localhost:8081/map");

        assertThat(policy.isAllowedWrite(request)).isTrue();
    }

    private MockHttpServletRequest writeRequest() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setScheme("http");
        request.addHeader("Host", "localhost:8081");
        request.addHeader("X-Requested-With", "XMLHttpRequest");
        return request;
    }
}
