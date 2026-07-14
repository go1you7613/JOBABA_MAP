package kr.go.tkjf.usr.map.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;

import javax.servlet.http.HttpServletRequest;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Component
class MapWriteOriginPolicy {

    private static final String AJAX_HEADER = "X-Requested-With";
    private static final String AJAX_VALUE = "XMLHttpRequest";

    private final List<String> allowedOrigins;

    MapWriteOriginPolicy(@Value("${jobaba.map.write.allowed-origins}") String origins) {
        this.allowedOrigins = Arrays.stream(origins.split(","))
                .map(String::trim)
                .filter(origin -> !origin.isEmpty())
                .map(origin -> origin.replaceAll("/+$", ""))
                .collect(Collectors.toList());
    }

    boolean isAllowedWrite(HttpServletRequest request) {
        if (!AJAX_VALUE.equals(request.getHeader(AJAX_HEADER))) {
            return false;
        }
        String origin = request.getHeader(HttpHeaders.ORIGIN);
        String referer = request.getHeader(HttpHeaders.REFERER);
        return allowedOrigins.stream().anyMatch(allowed -> matches(origin, allowed) || matches(referer, allowed));
    }

    private boolean matches(String value, String allowed) {
        return value != null && (value.equals(allowed) || value.startsWith(allowed + "/"));
    }
}
