package kr.go.tkjf.usr.map.controller;

import kr.go.tkjf.usr.map.service.MapService;
import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapSearchVO;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class MapApiControllerTest {

    @Test
    void getJobListReturnsTotalCountHeader() {
        MapApiController controller = new MapApiController(new StubMapService());

        ResponseEntity<List<JobPostingVO>> response = controller.getJobList(new MapSearchVO());

        assertThat(response.getHeaders().getFirst("X-Total-Count")).isEqualTo("486");
        assertThat(response.getBody()).hasSize(1);
    }

    private static class StubMapService implements MapService {
        @Override
        public List<JobPostingVO> getJobListByViewport(MapSearchVO searchVO) {
            return Collections.singletonList(new JobPostingVO());
        }

        @Override
        public int countJobListByViewport(MapSearchVO searchVO) {
            return 486;
        }

        @Override
        public JobPostingVO getJobDetail(String wantedAuthNo) {
            return null;
        }

        @Override
        public List<JobPostingVO> getJobListWithoutCoord(MapSearchVO searchVO) {
            return Collections.emptyList();
        }

        @Override
        public void saveCoord(MapCoordVO coordVO) {
        }
    }
}
