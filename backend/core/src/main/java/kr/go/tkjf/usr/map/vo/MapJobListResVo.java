package kr.go.tkjf.usr.map.vo;

import java.util.List;

public class MapJobListResVo {

    private List<JobPostingVO> jobs;
    private int totalCount;

    public MapJobListResVo() {
    }

    public MapJobListResVo(List<JobPostingVO> jobs, int totalCount) {
        this.jobs = jobs;
        this.totalCount = totalCount;
    }

    public List<JobPostingVO> getJobs() {
        return jobs;
    }

    public void setJobs(List<JobPostingVO> jobs) {
        this.jobs = jobs;
    }

    public int getTotalCount() {
        return totalCount;
    }

    public void setTotalCount(int totalCount) {
        this.totalCount = totalCount;
    }
}
