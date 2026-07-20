package kr.go.tkjf.usr.map.controller;

import org.junit.jupiter.api.Test;
import org.springframework.ui.ConcurrentModel;

import static org.assertj.core.api.Assertions.assertThat;

class MapControllerTest {

    private final MapController controller = new MapController("test-kakao-key");

    @Test
    void mapPageReturnsMapJspViewAndDefaultPartner() {
        ConcurrentModel model = new ConcurrentModel();

        String viewName = controller.mapPage(null, model);

        assertThat(viewName).isEqualTo("map/index");
        assertThat(model.getAttribute("partner")).isEqualTo("default");
        assertThat(model.getAttribute("kakaoJsKey")).isEqualTo("test-kakao-key");
    }

    @Test
    void sharePageReturnsMapShareJspView() {
        assertThat(controller.sharePage()).isEqualTo("map/map-share");
    }
}
