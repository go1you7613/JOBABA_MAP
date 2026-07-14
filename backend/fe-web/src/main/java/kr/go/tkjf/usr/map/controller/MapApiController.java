package kr.go.tkjf.usr.map.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import kr.go.tkjf.usr.map.client.MapBizHttpClient;
import kr.go.tkjf.usr.map.client.MapBizHttpException;
import kr.go.tkjf.usr.map.vo.JobPostingVO;
import kr.go.tkjf.usr.map.vo.MapApiResponse;
import kr.go.tkjf.usr.map.vo.MapCoordVO;
import kr.go.tkjf.usr.map.vo.MapJobListResVo;
import kr.go.tkjf.usr.map.vo.MapSearchVO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.Collections;
import java.util.List;

@RestController
@RequestMapping("/api/v1/map")
public class MapApiController {

    private final MapBizHttpClient mapBizHttpClient;
    private final MapWriteOriginPolicy mapWriteOriginPolicy;

    public MapApiController(MapBizHttpClient mapBizHttpClient, MapWriteOriginPolicy mapWriteOriginPolicy) {
        this.mapBizHttpClient = mapBizHttpClient;
        this.mapWriteOriginPolicy = mapWriteOriginPolicy;
    }

    @GetMapping("/jobs")
    public ResponseEntity<List<JobPostingVO>> getJobList(@Valid MapSearchVO searchVO) {
        MapApiResponse<MapJobListResVo> response = mapBizHttpClient.post(
                "/api/v1/biz/map/jobs", searchVO,
                new TypeReference<MapApiResponse<MapJobListResVo>>() { });
        MapJobListResVo body = response.getBody();
        List<JobPostingVO> jobs = body != null && body.getJobs() != null ? body.getJobs() : Collections.emptyList();
        int totalCount = body != null ? body.getTotalCount() : 0;
        return ResponseEntity.ok().header("X-Total-Count", Integer.toString(totalCount)).body(jobs);
    }

    @GetMapping("/jobs/{wantedAuthNo}")
    public ResponseEntity<JobPostingVO> getJobDetail(@PathVariable String wantedAuthNo) {
        MapApiResponse<JobPostingVO> response = mapBizHttpClient.post(
                "/api/v1/biz/map/jobs/detail", wantedAuthNo,
                new TypeReference<MapApiResponse<JobPostingVO>>() { });
        return response.getBody() == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(response.getBody());
    }

    @GetMapping("/jobs/coord-pending")
    public ResponseEntity<List<JobPostingVO>> getCoordPendingJobList(@Valid MapSearchVO searchVO) {
        MapApiResponse<List<JobPostingVO>> response = mapBizHttpClient.post(
                "/api/v1/biz/map/jobs/coord-pending", searchVO,
                new TypeReference<MapApiResponse<List<JobPostingVO>>>() { });
        return ResponseEntity.ok(response.getBody() == null ? Collections.emptyList() : response.getBody());
    }

    @PostMapping("/jobs/coords")
    public ResponseEntity<Void> saveJobCoord(@Valid @RequestBody MapCoordVO coordVO, HttpServletRequest request) {
        if (!mapWriteOriginPolicy.isAllowedWrite(request)) {
            return ResponseEntity.status(403).build();
        }
        mapBizHttpClient.post("/api/v1/biz/map/jobs/coords", coordVO,
                new TypeReference<MapApiResponse<Void>>() { });
        return ResponseEntity.noContent().build();
    }

    @ExceptionHandler(MapBizHttpException.class)
    public ResponseEntity<Void> handleMapBizHttpException(MapBizHttpException e) {
        return ResponseEntity.status(e.getStatusCode()).build();
    }
}
