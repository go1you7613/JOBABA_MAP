package kr.go.tkjf.usr.map.controller;

import kr.go.tkjf.usr.map.service.MapService;
import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapApiRequest;
import kr.go.tkjf.usr.map.vo.MapApiResponse;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapJobListResVo;
import kr.go.tkjf.usr.map.vo.MapSearchVO;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class MapApiControllerTest {

    @Test
    void getJobListReturnsBodyWithTotalCount() {
        MapApiController controller = new MapApiController();
        ReflectionTestUtils.setField(controller, "mapService", new StubMapService());

        MapApiResponse<MapJobListResVo> response = controller.getJobList(new MapApiRequest<>(new MapSearchVO()));

        assertThat(response.getBody().getTotalCount()).isEqualTo(486);
        assertThat(response.getBody().getJobs()).hasSize(1);
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
