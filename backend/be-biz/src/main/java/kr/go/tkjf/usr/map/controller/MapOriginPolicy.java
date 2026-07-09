package kr.go.tkjf.usr.map.controller;

import org.springframework.http.HttpHeaders;

import javax.servlet.http.HttpServletRequest;
import java.util.ArrayList;
import java.util.List;

public class MapOriginPolicy {

    private static final String AJAX_HEADER = "X-Requested-With";
    private static final String AJAX_VALUE = "XMLHttpRequest";

    private final List<String> allowedOrigins;

    public MapOriginPolicy(List<String> allowedOrigins) {
        this.allowedOrigins = normalizeOrigins(allowedOrigins);
    }

    boolean isAllowedWrite(HttpServletRequest request) {
        if (!AJAX_VALUE.equals(request.getHeader(AJAX_HEADER))) {
            return false;
        }

        String expected = request.getScheme() + "://" + request.getHeader(HttpHeaders.HOST);
        String origin = request.getHeader(HttpHeaders.ORIGIN);
        String referer = request.getHeader(HttpHeaders.REFERER);

        return matchesAllowed(origin, expected) || matchesAllowed(referer, expected);
    }

    private boolean matchesAllowed(String value, String expected) {
        if (matchesOrigin(value, expected)) {
            return true;
        }
        for (String allowedOrigin : allowedOrigins) {
            if (matchesOrigin(value, allowedOrigin)) {
                return true;
            }
        }
        return false;
    }

    private boolean matchesOrigin(String value, String expected) {
        return value != null && (value.equals(expected) || value.startsWith(expected + "/"));
    }

    private List<String> normalizeOrigins(List<String> origins) {
        List<String> normalized = new ArrayList<>();
        if (origins == null) {
            return normalized;
        }
        for (String origin : origins) {
            if (origin == null || origin.trim().isEmpty()) {
                continue;
            }
            normalized.add(origin.trim().replaceAll("/+$", ""));
        }
        return normalized;
    }
}
