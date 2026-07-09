package kr.go.tkjf;

import kr.go.tkjf.usr.map.controller.MapController;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackageClasses = {JobabaMapFeWebApplication.class, MapController.class})
public class JobabaMapFeWebApplication {
    public static void main(String[] args) {
        SpringApplication.run(JobabaMapFeWebApplication.class, args);
    }
}
