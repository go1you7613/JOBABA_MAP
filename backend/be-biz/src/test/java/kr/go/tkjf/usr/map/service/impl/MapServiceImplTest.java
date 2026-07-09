package kr.go.tkjf.usr.map.service.impl;

import kr.go.tkjf.usr.map.dao.MapDao;
import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapSearchVO;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class MapServiceImplTest {

    @Test
    void getJobListByViewportPassesRequestedPageAndSizeToDao() {
        CapturingMapDao mapDao = new CapturingMapDao();
        MapServiceImpl service = new MapServiceImpl(mapDao);
        MapSearchVO searchVO = new MapSearchVO();
        searchVO.setSwLat("36.6");
        searchVO.setSwLng("126.5");
        searchVO.setNeLat("38.3");
        searchVO.setNeLng("128.0");
        searchVO.setPage(2);
        searchVO.setSize(200);

        service.getJobListByViewport(searchVO);

        assertThat(mapDao.capturedPage).isEqualTo(2);
        assertThat(mapDao.capturedSize).isEqualTo(200);
        assertThat(mapDao.capturedOffset).isEqualTo(200);
    }

    @Test
    void countJobListByViewportPassesNormalizedSearchToDao() {
        CapturingMapDao mapDao = new CapturingMapDao();
        MapServiceImpl service = new MapServiceImpl(mapDao);
        MapSearchVO searchVO = new MapSearchVO();
        searchVO.setSwLat("38.3");
        searchVO.setSwLng("128.0");
        searchVO.setNeLat("36.6");
        searchVO.setNeLng("126.5");

        int count = service.countJobListByViewport(searchVO);

        assertThat(count).isEqualTo(486);
        assertThat(mapDao.countCalled).isTrue();
        assertThat(searchVO.getSwLat()).isEqualTo("36.6");
        assertThat(searchVO.getNeLat()).isEqualTo("38.3");
    }

    private static class CapturingMapDao implements MapDao {
        private int capturedPage;
        private int capturedSize;
        private int capturedOffset;
        private boolean countCalled;

        @Override
        public List<JobPostingVO> selectJobListByViewport(MapSearchVO searchVO) {
            capturedPage = searchVO.getPage();
            capturedSize = searchVO.getSize();
            capturedOffset = searchVO.getOffset();
            return Collections.emptyList();
        }

        @Override
        public int countJobListByViewport(MapSearchVO searchVO) {
            countCalled = true;
            return 486;
        }

        @Override
        public JobPostingVO selectJobDetail(String wantedAuthNo) {
            return null;
        }

        @Override
        public int countJobPosting(String wantedAuthNo) {
            return 0;
        }

        @Override
        public List<JobPostingVO> selectJobListWithoutCoord(MapSearchVO searchVO) {
            return Collections.emptyList();
        }

        @Override
        public int insertCoord(MapCoordVO coordVO) {
            return 0;
        }
    }
}
