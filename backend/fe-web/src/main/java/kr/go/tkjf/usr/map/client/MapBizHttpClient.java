package kr.go.tkjf.usr.map.client;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.go.tkjf.usr.map.vo.MapApiRequest;
import kr.go.tkjf.usr.map.vo.MapApiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;

@Component
public class MapBizHttpClient {

    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(3);
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(5);
    private static final Set<String> ALLOWED_PATHS = Set.of(
            "/api/v1/biz/map/jobs",
            "/api/v1/biz/map/jobs/detail",
            "/api/v1/biz/map/jobs/coord-pending",
            "/api/v1/biz/map/jobs/coords"
    );

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final Set<String> allowedHosts;
    private final URI baseUri;

    @Autowired
    public MapBizHttpClient(ObjectMapper objectMapper,
                            @Value("${jobaba.map.biz-base-url}") String bizBaseUrl,
                            @Value("${jobaba.map.biz-allowed-hosts}") String allowedHosts) {
        this(objectMapper, HttpClient.newBuilder()
                .connectTimeout(CONNECT_TIMEOUT)
                .followRedirects(HttpClient.Redirect.NEVER).build(), bizBaseUrl, allowedHosts);
    }

    MapBizHttpClient(ObjectMapper objectMapper, HttpClient httpClient, String bizBaseUrl, String allowedHosts) {
        this.objectMapper = objectMapper;
        this.httpClient = httpClient;
        this.allowedHosts = Arrays.stream(allowedHosts.split(","))
                .map(String::trim)
                .filter(host -> !host.isEmpty())
                .collect(Collectors.toUnmodifiableSet());
        this.baseUri = validateBaseUri(bizBaseUrl);
    }

    public <T> MapApiResponse<T> post(String path, Object body,
                                       TypeReference<MapApiResponse<T>> responseType) {
        URI target = buildTargetUri(path);
        try {
            String requestJson = objectMapper.writeValueAsString(new MapApiRequest<>(body));
            HttpRequest request = HttpRequest.newBuilder(target)
                    .timeout(REQUEST_TIMEOUT)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(requestJson))
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new MapBizHttpException(response.statusCode() >= 400 && response.statusCode() < 500
                        ? response.statusCode() : 502);
            }
            return objectMapper.readValue(response.body(), responseType);
        } catch (JsonProcessingException e) {
            throw new MapBizHttpException(502);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new MapBizHttpException(502);
        } catch (IOException e) {
            throw new MapBizHttpException(502);
        }
    }

    private URI buildTargetUri(String path) {
        if (!ALLOWED_PATHS.contains(path)) {
            throw new IllegalArgumentException("Unsupported map API path");
        }
        return baseUri.resolve(path);
    }

    private URI validateBaseUri(String value) {
        try {
            URI uri = URI.create(value);
            if (("http".equals(uri.getScheme()) || "https".equals(uri.getScheme()))
                    && uri.getHost() != null
                    && allowedHosts.contains(uri.getHost())
                    && uri.getUserInfo() == null
                    && uri.getQuery() == null
                    && uri.getFragment() == null
                    && (uri.getPath() == null || uri.getPath().isEmpty() || "/".equals(uri.getPath()))) {
                return new URI(uri.getScheme(), null, uri.getHost(), uri.getPort(), "/", null, null);
            }
        } catch (Exception ignored) {
            // Invalid configuration is handled below without exposing it to callers.
        }
        throw new IllegalStateException("Invalid jobaba.map.biz-base-url configuration");
    }
}
