package kr.go.tkjf.usr.map.controller;

import kr.go.tkjf.usr.map.service.MapService;
import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapApiRequest;
import kr.go.tkjf.usr.map.vo.MapApiResponse;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapJobListResVo;
import kr.go.tkjf.usr.map.vo.MapSearchVO;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

@Validated
@RestController
@RequestMapping("/api/v1/biz/map")
public class MapApiController {

    @Resource
    private MapService mapService;
    @PostMapping("/jobs")
    public MapApiResponse<MapJobListResVo> getJobList(@Valid @RequestBody MapApiRequest<MapSearchVO> request) {
        MapSearchVO searchVO = request.getBody();
        List<JobPostingVO> jobs = mapService.getJobListByViewport(searchVO);
        int totalCount = mapService.countJobListByViewport(searchVO);
        return new MapApiResponse<>(new MapJobListResVo(jobs, totalCount));
    }

    @PostMapping("/jobs/detail")
    public MapApiResponse<JobPostingVO> getJobDetail(@RequestBody MapApiRequest<String> request) {
        return new MapApiResponse<>(mapService.getJobDetail(request.getBody()));
    }

    @PostMapping("/jobs/coord-pending")
    public MapApiResponse<List<JobPostingVO>> getCoordPendingJobList(
            @Valid @RequestBody MapApiRequest<MapSearchVO> request) {
        return new MapApiResponse<>(mapService.getJobListWithoutCoord(request.getBody()));
    }

    @PostMapping("/jobs/coords")
    public MapApiResponse<Void> saveJobCoord(@Valid @RequestBody MapApiRequest<MapCoordVO> request) {
        mapService.saveCoord(request.getBody());
        return new MapApiResponse<>();
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Void> handleIllegalArgumentException() {
        return ResponseEntity.badRequest().build();
    }
}
