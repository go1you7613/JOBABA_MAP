package kr.go.tkjf.usr.map.service.impl;

import kr.go.tkjf.usr.map.dao.MapDao;
import kr.go.tkjf.usr.map.service.MapService;
import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapSearchVO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class MapServiceImpl implements MapService {

    private static final Set<String> SORT_TYPES = Set.of("regDt", "closeDt");
    private static final Set<String> SOURCE_TYPES = Set.of("PUB", "PRV");
    private static final Set<String> PUBLIC_NCS_CODES = Set.of(
            "R600001", "R600002", "R600003", "R600004", "R600005",
            "R600006", "R600007", "R600008", "R600009", "R600010",
            "R600011", "R600012", "R600013", "R600014", "R600015",
            "R600016", "R600017", "R600018", "R600019", "R600020",
            "R600021", "R600022", "R600023", "R600024", "R600025"
    );
    private static final Set<String> PUBLIC_CAREER_CODES = Set.of("R2010", "R2020", "R2030", "R2040");
    private static final Set<String> PUBLIC_EDUCATION_CODES = Set.of("R7010", "R7020", "R7030", "R7040", "R7050", "R7060", "R7070");
    private static final Set<String> PUBLIC_EMPLOYMENT_CODES = Set.of("R1010", "R1020", "R1030", "R1040", "R1050", "R1060", "R1070");
    private static final Set<String> PRIVATE_JOB_CODES = Set.of("0", "1", "2", "3", "4", "5", "6", "7", "8", "9");
    private static final Set<String> PRIVATE_CAREER_CODES = Set.of("1", "2", "3", "4");
    private static final Set<String> PRIVATE_EDUCATION_CODES = Set.of("0", "3", "4", "5", "7");
    private static final Set<String> PRIVATE_EMPLOYMENT_CODES = Set.of("1", "2", "3", "6", "7");

    private final MapDao mapDao;

    @Override
    public List<JobPostingVO> getJobListByViewport(MapSearchVO searchVO) {
        normalizeSearch(searchVO, true);
        setOffset(searchVO);
        return mapDao.selectJobListByViewport(searchVO);
    }

    @Override
    public int countJobListByViewport(MapSearchVO searchVO) {
        normalizeSearch(searchVO, true);
        return mapDao.countJobListByViewport(searchVO);
    }

    @Override
    public JobPostingVO getJobDetail(String wantedAuthNo) {
        validateWantedAuthNo(wantedAuthNo);
        return mapDao.selectJobDetail(wantedAuthNo);
    }

    private int normalizeSize(int size) {
        if (size <= 0) return 20;
        return Math.min(size, 200);
    }

    private int normalizePage(int page) {
        return page > 0 ? page : 1;
    }

    private void setOffset(MapSearchVO searchVO) {
        int page = normalizePage(searchVO.getPage());
        int size = normalizeSize(searchVO.getSize());
        searchVO.setPage(page);
        searchVO.setSize(size);
        searchVO.setOffset((page - 1) * size);
    }

    @Override
    public List<JobPostingVO> getJobListWithoutCoord(MapSearchVO searchVO) {
        normalizeSearch(searchVO, false);
        setOffset(searchVO);
        return mapDao.selectJobListWithoutCoord(searchVO);
    }

    @Override
    public void saveCoord(MapCoordVO coordVO) {
        validateCoord(coordVO);
        if (mapDao.countJobPosting(coordVO.getWantedAuthNo()) < 1) {
            throw new IllegalArgumentException("존재하지 않는 공고입니다.");
        }
        coordVO.setGeocodeYn("Y");
        mapDao.insertCoord(coordVO);
    }

    private void normalizeSearch(MapSearchVO searchVO, boolean requireBounds) {
        if (searchVO == null) {
            throw new IllegalArgumentException("검색 조건이 없습니다.");
        }
        if (requireBounds) {
            double swLat = parseCoordinate(searchVO.getSwLat(), "남서 위도");
            double swLng = parseCoordinate(searchVO.getSwLng(), "남서 경도");
            double neLat = parseCoordinate(searchVO.getNeLat(), "북동 위도");
            double neLng = parseCoordinate(searchVO.getNeLng(), "북동 경도");
            if (swLat < -90 || swLat > 90 || neLat < -90 || neLat > 90
                    || swLng < -180 || swLng > 180 || neLng < -180 || neLng > 180) {
                throw new IllegalArgumentException("지도 좌표 범위가 올바르지 않습니다.");
            }
            searchVO.setSwLat(Double.toString(Math.min(swLat, neLat)));
            searchVO.setNeLat(Double.toString(Math.max(swLat, neLat)));
            searchVO.setSwLng(Double.toString(Math.min(swLng, neLng)));
            searchVO.setNeLng(Double.toString(Math.max(swLng, neLng)));
        }

        searchVO.setKeyword(trimToMax(searchVO.getKeyword(), 50));
        validateOptionalCode(searchVO.getSourceType(), SOURCE_TYPES, "채널 구분");
        validateOptionalCodes(searchVO.getJobNcsCd(), PUBLIC_NCS_CODES, "공공 직종");
        validateOptionalCodes(searchVO.getJobCareerCd(), PUBLIC_CAREER_CODES, "공공 경력");
        validateOptionalCodes(searchVO.getJobAcdmcrCd(), PUBLIC_EDUCATION_CODES, "공공 학력");
        validateOptionalCodes(searchVO.getJobEmpTpCd(), PUBLIC_EMPLOYMENT_CODES, "공공 고용형태");
        validateOptionalCodes(searchVO.getPrvJobCd(), PRIVATE_JOB_CODES, "민간 직종");
        validateOptionalCodes(searchVO.getPrvCareerCd(), PRIVATE_CAREER_CODES, "민간 경력");
        validateOptionalCodes(searchVO.getPrvEduCd(), PRIVATE_EDUCATION_CODES, "민간 학력");
        validateOptionalCodes(searchVO.getPrvEmpTpCd(), PRIVATE_EMPLOYMENT_CODES, "민간 고용형태");
        if (isBlank(searchVO.getSortType())) {
            searchVO.setSortType("regDt");
        }
        validateOptionalCode(searchVO.getSortType(), SORT_TYPES, "정렬");
    }

    private void validateOptionalCode(String value, Set<String> allowed, String label) {
        if (!isBlank(value) && !allowed.contains(value)) {
            throw new IllegalArgumentException(label + " 값이 올바르지 않습니다.");
        }
    }

    private void validateOptionalCodes(List<String> values, Set<String> allowed, String label) {
        if (values == null) return;
        for (String value : values) {
            validateOptionalCode(value, allowed, label);
        }
    }

    private String trimToMax(String value, int maxLength) {
        if (value == null) return null;
        String trimmed = value.trim();
        if (trimmed.length() > maxLength) {
            throw new IllegalArgumentException("검색어가 너무 깁니다.");
        }
        return trimmed.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private void validateCoord(MapCoordVO coordVO) {
        if (coordVO == null) {
            throw new IllegalArgumentException("좌표 정보가 없습니다.");
        }
        String wantedAuthNo = coordVO.getWantedAuthNo();
        validateWantedAuthNo(wantedAuthNo);

        double lat = parseCoordinate(coordVO.getLat(), "위도");
        double lng = parseCoordinate(coordVO.getLng(), "경도");
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            throw new IllegalArgumentException("좌표 범위가 올바르지 않습니다.");
        }
        coordVO.setLat(Double.toString(lat));
        coordVO.setLng(Double.toString(lng));
    }

    private void validateWantedAuthNo(String wantedAuthNo) {
        if (wantedAuthNo == null || wantedAuthNo.isBlank()
                || wantedAuthNo.length() > 50
                || !wantedAuthNo.matches("[A-Za-z0-9_-]+")) {
            throw new IllegalArgumentException("공고 식별자가 올바르지 않습니다.");
        }
    }

    private double parseCoordinate(String value, String label) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(label + " 값이 없습니다.");
        }
        try {
            return Double.parseDouble(value);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(label + " 값이 숫자가 아닙니다.");
        }
    }
}
