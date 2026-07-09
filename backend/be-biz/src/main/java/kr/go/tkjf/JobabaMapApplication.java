package kr.go.tkjf;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("kr.go.tkjf.usr.map.dao")
public class JobabaMapApplication {
    public static void main(String[] args) {
        SpringApplication.run(JobabaMapApplication.class, args);
    }
}
