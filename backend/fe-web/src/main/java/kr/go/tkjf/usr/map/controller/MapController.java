package kr.go.tkjf.usr.map.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class MapController {

    private final String kakaoJsKey;

    public MapController(@Value("${jobaba.map.kakao-js-key:}") String kakaoJsKey) {
        this.kakaoJsKey = kakaoJsKey;
    }

    // 일자리 맵 페이지 (팝업)
    @GetMapping("/map")
    public String mapPage(@RequestParam(required = false) String partner, Model model) {
        addMapAttributes(partner != null ? partner : "default", model);
        return "map/index";
    }

    @GetMapping("/map/share")
    public String sharePage() {
        return "map/map-share";
    }

    private void addMapAttributes(String partner, Model model) {
        model.addAttribute("partner", partner);
        model.addAttribute("kakaoJsKey", kakaoJsKey);
    }
}
