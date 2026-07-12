package kr.go.tkjf.usr.map.service.impl;

import kr.go.tkjf.usr.map.dao.MapDao;
import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapSearchVO;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class MapServiceImplTest {

    @Test
    void getJobListByViewportPassesRequestedPageAndSizeToDao() {
        CapturingMapDao mapDao = new CapturingMapDao();
        MapServiceImpl service = new MapServiceImpl();
        ReflectionTestUtils.setField(service, "mapDao", mapDao);
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
        MapServiceImpl service = new MapServiceImpl();
        ReflectionTestUtils.setField(service, "mapDao", mapDao);
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

    @Test
    void getJobListWithoutCoordPassesValidSalaryRangeToDao() {
        CapturingMapDao mapDao = new CapturingMapDao();
        MapServiceImpl service = new MapServiceImpl();
        ReflectionTestUtils.setField(service, "mapDao", mapDao);
        MapSearchVO searchVO = new MapSearchVO();
        searchVO.setSalaryType("연봉");
        searchVO.setSalaryMin(3000L);
        searchVO.setSalaryMax(4000L);

        service.getJobListWithoutCoord(searchVO);

        assertThat(mapDao.capturedWithoutCoordSearch.getSalaryType()).isEqualTo("연봉");
        assertThat(mapDao.capturedWithoutCoordSearch.getSalaryMin()).isEqualTo(3000L);
        assertThat(mapDao.capturedWithoutCoordSearch.getSalaryMax()).isEqualTo(4000L);
    }

    @Test
    void getJobListWithoutCoordRejectsInvalidSalaryFilters() {
        CapturingMapDao mapDao = new CapturingMapDao();
        MapServiceImpl service = new MapServiceImpl();
        ReflectionTestUtils.setField(service, "mapDao", mapDao);

        MapSearchVO invalidType = new MapSearchVO();
        invalidType.setSalaryType("주급");
        assertThatThrownBy(() -> service.getJobListWithoutCoord(invalidType))
                .isInstanceOf(IllegalArgumentException.class);

        MapSearchVO negative = new MapSearchVO();
        negative.setSalaryType("시급");
        negative.setSalaryMin(-1L);
        assertThatThrownBy(() -> service.getJobListWithoutCoord(negative))
                .isInstanceOf(IllegalArgumentException.class);

        MapSearchVO missingType = new MapSearchVO();
        missingType.setSalaryMin(100L);
        assertThatThrownBy(() -> service.getJobListWithoutCoord(missingType))
                .isInstanceOf(IllegalArgumentException.class);

        MapSearchVO reversed = new MapSearchVO();
        reversed.setSalaryType("월급");
        reversed.setSalaryMin(400L);
        reversed.setSalaryMax(200L);
        assertThatThrownBy(() -> service.getJobListWithoutCoord(reversed))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void salaryNoConditionClearsOtherSalaryValues() {
        CapturingMapDao mapDao = new CapturingMapDao();
        MapServiceImpl service = new MapServiceImpl();
        ReflectionTestUtils.setField(service, "mapDao", mapDao);
        MapSearchVO searchVO = new MapSearchVO();
        searchVO.setSalaryNoCondition(true);
        searchVO.setSalaryType("주급");
        searchVO.setSalaryMin(-1L);
        searchVO.setSalaryMax(-2L);

        service.getJobListWithoutCoord(searchVO);

        assertThat(mapDao.capturedWithoutCoordSearch.isSalaryNoCondition()).isTrue();
        assertThat(mapDao.capturedWithoutCoordSearch.getSalaryType()).isNull();
        assertThat(mapDao.capturedWithoutCoordSearch.getSalaryMin()).isNull();
        assertThat(mapDao.capturedWithoutCoordSearch.getSalaryMax()).isNull();
    }

    private static class CapturingMapDao extends MapDao {
        private int capturedPage;
        private int capturedSize;
        private int capturedOffset;
        private boolean countCalled;
        private MapSearchVO capturedWithoutCoordSearch;

        public List<JobPostingVO> selectJobListByViewport(MapSearchVO searchVO) {
            capturedPage = searchVO.getPage();
            capturedSize = searchVO.getSize();
            capturedOffset = searchVO.getOffset();
            return Collections.emptyList();
        }

        public int countJobListByViewport(MapSearchVO searchVO) {
            countCalled = true;
            return 486;
        }

        public JobPostingVO selectJobDetail(String wantedAuthNo) {
            return null;
        }

        public int countJobPosting(String wantedAuthNo) {
            return 0;
        }

        public List<JobPostingVO> selectJobListWithoutCoord(MapSearchVO searchVO) {
            capturedWithoutCoordSearch = searchVO;
            return Collections.emptyList();
        }

        public int insertCoord(MapCoordVO coordVO) {
            return 0;
        }
    }
}
