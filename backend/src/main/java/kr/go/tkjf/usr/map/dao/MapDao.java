package kr.go.tkjf.usr.map.dao;

import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapSearchVO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface MapDao {

    // 뷰포트 내 채용공고 목록 (좌표 포함)
    List<JobPostingVO> selectJobListByViewport(MapSearchVO searchVO);

    // 뷰포트 내 채용공고 총 건수
    int countJobListByViewport(MapSearchVO searchVO);

    // 채용공고 상세
    JobPostingVO selectJobDetail(String wantedAuthNo);

    // 좌표 저장 전 공고 존재 확인
    int countJobPosting(String wantedAuthNo);

    // 좌표 미변환 공고 목록
    List<JobPostingVO> selectJobListWithoutCoord(MapSearchVO searchVO);

    // 좌표 저장
    int insertCoord(MapCoordVO coordVO);
}
