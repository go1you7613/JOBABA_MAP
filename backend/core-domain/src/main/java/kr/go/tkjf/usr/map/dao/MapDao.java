package kr.go.tkjf.usr.map.dao;

import com.BnLSoft.cmmn.base.BaseDao;
import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapSearchVO;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class MapDao extends BaseDao {

    // 뷰포트 내 채용공고 목록 (좌표 포함)
    @SuppressWarnings("unchecked")
    public List<JobPostingVO> selectJobListByViewport(MapSearchVO searchVO) throws DataAccessException {
        return (List<JobPostingVO>) list("map.selectJobListByViewport", searchVO);
    }

    // 뷰포트 내 채용공고 총 건수
    public int countJobListByViewport(MapSearchVO searchVO) throws DataAccessException {
        return (Integer) select("map.countJobListByViewport", searchVO);
    }

    // 채용공고 상세
    public JobPostingVO selectJobDetail(String wantedAuthNo) throws DataAccessException {
        return (JobPostingVO) select("map.selectJobDetail", wantedAuthNo);
    }

    // 좌표 저장 전 공고 존재 확인
    public int countJobPosting(String wantedAuthNo) throws DataAccessException {
        return (Integer) select("map.countJobPosting", wantedAuthNo);
    }

    // 좌표 미변환 공고 목록
    @SuppressWarnings("unchecked")
    public List<JobPostingVO> selectJobListWithoutCoord(MapSearchVO searchVO) throws DataAccessException {
        return (List<JobPostingVO>) list("map.selectJobListWithoutCoord", searchVO);
    }

    // 좌표 저장
    public int insertCoord(MapCoordVO coordVO) throws DataAccessException {
        return insert("map.insertCoord", coordVO);
    }
}
