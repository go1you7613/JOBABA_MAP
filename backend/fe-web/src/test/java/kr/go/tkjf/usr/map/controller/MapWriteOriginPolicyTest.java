package kr.go.tkjf.usr.map.controller;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

import static org.assertj.core.api.Assertions.assertThat;

class MapWriteOriginPolicyTest {

    private final MapWriteOriginPolicy policy = new MapWriteOriginPolicy("https://job.gg.go.kr");

    @Test
    void allowsConfiguredOriginForAjaxWrite() {
        MockHttpServletRequest request = writeRequest();
        request.addHeader("Origin", "https://job.gg.go.kr");

        assertThat(policy.isAllowedWrite(request)).isTrue();
    }

    @Test
    void rejectsUntrustedOriginForAjaxWrite() {
        MockHttpServletRequest request = writeRequest();
        request.addHeader("Origin", "https://evil.example");

        assertThat(policy.isAllowedWrite(request)).isFalse();
    }

    private MockHttpServletRequest writeRequest() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("X-Requested-With", "XMLHttpRequest");
        return request;
    }
}
