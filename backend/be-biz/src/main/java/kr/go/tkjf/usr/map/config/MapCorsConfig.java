package kr.go.tkjf.usr.map.config;

import kr.go.tkjf.usr.map.controller.MapOriginPolicy;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Configuration
public class MapCorsConfig {

    @Bean
    public List<String> mapAllowedOrigins(
            @Value("${jobaba.map.cors.allowed-origins:http://localhost:8080}") String allowedOrigins) {
        return Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(origin -> !origin.isEmpty())
                .map(origin -> origin.replaceAll("/+$", ""))
                .collect(Collectors.toList());
    }

    @Bean
    public MapOriginPolicy mapOriginPolicy(@Qualifier("mapAllowedOrigins") List<String> mapAllowedOrigins) {
        return new MapOriginPolicy(mapAllowedOrigins);
    }

    @Bean
    public WebMvcConfigurer mapCorsConfigurer(@Qualifier("mapAllowedOrigins") List<String> mapAllowedOrigins) {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/v1/map/**")
                        .allowedOrigins(mapAllowedOrigins.toArray(new String[0]))
                        .allowedMethods("GET", "POST", "OPTIONS")
                        .allowedHeaders("Content-Type", "X-Requested-With")
                        .exposedHeaders("X-Total-Count")
                        .maxAge(3600);
            }
        };
    }
}
