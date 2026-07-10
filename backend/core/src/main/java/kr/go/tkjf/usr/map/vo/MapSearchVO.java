package kr.go.tkjf.usr.map.vo;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;
import java.util.ArrayList;
import java.util.List;

public class MapSearchVO {

    private static final String COORD_PATTERN = "-?\\d{1,3}(\\.\\d{1,15})?";

    // 지도 뷰포트 범위
    @Pattern(regexp = COORD_PATTERN)
    private String swLat;      // 남서 위도
    @Pattern(regexp = COORD_PATTERN)
    private String swLng;      // 남서 경도
    @Pattern(regexp = COORD_PATTERN)
    private String neLat;      // 북동 위도
    @Pattern(regexp = COORD_PATTERN)
    private String neLng;      // 북동 경도

    // 키워드 검색
    @Size(max = 50)
    private String keyword;

    // 채널 구분 (PUB=공공, PRV=민간, null=전체)
    @Pattern(regexp = "|PUB|PRV")
    private String sourceType;

    // 공공 필터 (NCS 선택값은 JOBABA_CMMN_276 매핑으로 조회)
    private List<@Pattern(regexp = "R6000(0[1-9]|1[0-9]|2[0-5])") String> jobNcsCd = new ArrayList<>();
    private List<@Pattern(regexp = "R20(10|20|30|40)") String> jobCareerCd = new ArrayList<>();
    private List<@Pattern(regexp = "R70(10|20|30|40|50|60|70)") String> jobAcdmcrCd = new ArrayList<>();
    private List<@Pattern(regexp = "R10(10|20|30|40|50|60|70)") String> jobEmpTpCd = new ArrayList<>();

    // 민간 필터 (원천코드 기반 - jobkorea)
    private List<@Pattern(regexp = "[0-9]") String> prvJobCd = new ArrayList<>();
    private List<@Pattern(regexp = "[1-4]") String> prvCareerCd = new ArrayList<>();
    private List<@Pattern(regexp = "[03457]") String> prvEduCd = new ArrayList<>();
    private List<@Pattern(regexp = "[12367]") String> prvEmpTpCd = new ArrayList<>();

    // 정렬
    @Pattern(regexp = "|regDt|closeDt")
    private String sortType;       // regDt(등록일순) | closeDt(마감일순)

    // 페이징
    @Min(1)
    private int page = 1;
    @Min(1)
    @Max(200)
    private int size = 20;
    private int offset = 0;

    public String getSwLat() {
        return swLat;
    }

    public void setSwLat(String swLat) {
        this.swLat = swLat;
    }

    public String getSwLng() {
        return swLng;
    }

    public void setSwLng(String swLng) {
        this.swLng = swLng;
    }

    public String getNeLat() {
        return neLat;
    }

    public void setNeLat(String neLat) {
        this.neLat = neLat;
    }

    public String getNeLng() {
        return neLng;
    }

    public void setNeLng(String neLng) {
        this.neLng = neLng;
    }

    public String getKeyword() {
        return keyword;
    }

    public void setKeyword(String keyword) {
        this.keyword = keyword;
    }

    public String getSourceType() {
        return sourceType;
    }

    public void setSourceType(String sourceType) {
        this.sourceType = sourceType;
    }

    public List<String> getJobNcsCd() {
        return jobNcsCd;
    }

    public void setJobNcsCd(List<String> jobNcsCd) {
        this.jobNcsCd = jobNcsCd;
    }

    public List<String> getJobCareerCd() {
        return jobCareerCd;
    }

    public void setJobCareerCd(List<String> jobCareerCd) {
        this.jobCareerCd = jobCareerCd;
    }

    public List<String> getJobAcdmcrCd() {
        return jobAcdmcrCd;
    }

    public void setJobAcdmcrCd(List<String> jobAcdmcrCd) {
        this.jobAcdmcrCd = jobAcdmcrCd;
    }

    public List<String> getJobEmpTpCd() {
        return jobEmpTpCd;
    }

    public void setJobEmpTpCd(List<String> jobEmpTpCd) {
        this.jobEmpTpCd = jobEmpTpCd;
    }

    public List<String> getPrvJobCd() {
        return prvJobCd;
    }

    public void setPrvJobCd(List<String> prvJobCd) {
        this.prvJobCd = prvJobCd;
    }

    public List<String> getPrvCareerCd() {
        return prvCareerCd;
    }

    public void setPrvCareerCd(List<String> prvCareerCd) {
        this.prvCareerCd = prvCareerCd;
    }

    public List<String> getPrvEduCd() {
        return prvEduCd;
    }

    public void setPrvEduCd(List<String> prvEduCd) {
        this.prvEduCd = prvEduCd;
    }

    public List<String> getPrvEmpTpCd() {
        return prvEmpTpCd;
    }

    public void setPrvEmpTpCd(List<String> prvEmpTpCd) {
        this.prvEmpTpCd = prvEmpTpCd;
    }

    public String getSortType() {
        return sortType;
    }

    public void setSortType(String sortType) {
        this.sortType = sortType;
    }

    public int getPage() {
        return page;
    }

    public void setPage(int page) {
        this.page = page;
    }

    public int getSize() {
        return size;
    }

    public void setSize(int size) {
        this.size = size;
    }

    public int getOffset() {
        return offset;
    }

    public void setOffset(int offset) {
        this.offset = offset;
    }
}
