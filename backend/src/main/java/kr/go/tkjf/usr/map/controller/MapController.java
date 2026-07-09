package kr.go.tkjf.usr.map.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.ui.Model;

@Controller
public class MapController {

    @GetMapping("/")
    public String rootPage() {
        return "forward:/map/index.html";
    }

    // 일자리 맵 페이지 (팝업)
    @GetMapping("/map")
    public String mapPage(@RequestParam(required = false) String partner, Model model) {
        model.addAttribute("partner", partner != null ? partner : "default");
        return "forward:/map/index.html";
    }
}
