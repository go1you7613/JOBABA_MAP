package kr.go.tkjf.usr.map.controller;

import kr.go.tkjf.usr.map.service.MapService;
import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapSearchVO;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.List;

@Validated
@RestController
@RequestMapping("/api/v1/map")
public class MapApiController {

    @Resource
    private MapService mapService;
    @Resource
    private MapOriginPolicy mapOriginPolicy;

    @GetMapping("/jobs")
    public ResponseEntity<List<JobPostingVO>> getJobList(@Valid MapSearchVO searchVO) {
        List<JobPostingVO> jobs = mapService.getJobListByViewport(searchVO);
        int totalCount = mapService.countJobListByViewport(searchVO);
        return ResponseEntity.ok()
                .header("X-Total-Count", Integer.toString(totalCount))
                .body(jobs);
    }

    @GetMapping("/jobs/{wantedAuthNo}")
    public ResponseEntity<JobPostingVO> getJobDetail(@PathVariable String wantedAuthNo) {
        try {
            JobPostingVO job = mapService.getJobDetail(wantedAuthNo);
            if (job == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(job);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/jobs/coord-pending")
    public ResponseEntity<List<JobPostingVO>> getCoordPendingJobList(@Valid MapSearchVO searchVO) {
        return ResponseEntity.ok(mapService.getJobListWithoutCoord(searchVO));
    }

    @PostMapping("/jobs/coords")
    public ResponseEntity<Void> saveJobCoord(@Valid @RequestBody MapCoordVO coordVO,
                                             HttpServletRequest request) {
        if (!mapOriginPolicy.isAllowedWrite(request)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        try {
            mapService.saveCoord(coordVO);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
