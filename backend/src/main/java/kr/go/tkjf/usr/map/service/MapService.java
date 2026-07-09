package kr.go.tkjf.usr.map.service;

import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapSearchVO;

import java.util.List;

public interface MapService {

    List<JobPostingVO> getJobListByViewport(MapSearchVO searchVO);

    int countJobListByViewport(MapSearchVO searchVO);

    JobPostingVO getJobDetail(String wantedAuthNo);

    List<JobPostingVO> getJobListWithoutCoord(MapSearchVO searchVO);

    void saveCoord(MapCoordVO coordVO);
}
