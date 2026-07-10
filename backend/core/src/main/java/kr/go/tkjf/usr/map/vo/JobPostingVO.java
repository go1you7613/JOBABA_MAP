package kr.go.tkjf.usr.map.vo;

public class JobPostingVO {

    // 공고 식별
    private String wantedAuthNo;   // PK
    private String source;         // 채널명 (공공기관 | 잡코리아 | ...)
    private String sourceType;     // 채널 구분 (공공 | 민간)

    // 공고 기본 정보
    private String company;        // 회사명
    private String title;          // 공고제목
    private String jobsNm;         // 직무명
    private String jobsCd;         // 직종코드 (원천)
    private String empTpNm;        // 고용형태명
    private String career;         // 경력명
    private String minEdubg;       // 학력명
    private String salAmt;         // 임금
    private String salTpNm;        // 임금유형
    private String region;         // 지역명
    private String closeDt;        // 마감일
    private String wantedInfoUrl;  // 지원URL
    private String basicAddr;      // 기본주소
    private String detailAddr;     // 상세주소
    private String infoSvc;        // 서비스구분(공공/민간)

    // 통합 필터 컬럼 (JOB_ 계열 - R코드)
    private String jobCareerCd;    // 통합 경력코드  (R2000)
    private String jobAcdmcrCd;    // 통합 학력코드  (R7000)
    private String jobEmpTpCd;     // 통합 고용형태코드 (R1000)
    private String jobAreaCd;      // 통합 지역코드  (R3000)
    private String jobabaCmmn276Cd; // (신)잡아바 3차 직종코드
    private String jobabaCmmn274Cd; // (신)잡아바 1차 직종코드

    // 사용/삭제 여부
    private String useYn;
    private String delYn;

    // tb_empmn_map_coord (좌표 캐시)
    private String lat;            // 위도
    private String lng;            // 경도

    public String getWantedAuthNo() {
        return wantedAuthNo;
    }

    public void setWantedAuthNo(String wantedAuthNo) {
        this.wantedAuthNo = wantedAuthNo;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public String getSourceType() {
        return sourceType;
    }

    public void setSourceType(String sourceType) {
        this.sourceType = sourceType;
    }

    public String getCompany() {
        return company;
    }

    public void setCompany(String company) {
        this.company = company;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getJobsNm() {
        return jobsNm;
    }

    public void setJobsNm(String jobsNm) {
        this.jobsNm = jobsNm;
    }

    public String getJobsCd() {
        return jobsCd;
    }

    public void setJobsCd(String jobsCd) {
        this.jobsCd = jobsCd;
    }

    public String getEmpTpNm() {
        return empTpNm;
    }

    public void setEmpTpNm(String empTpNm) {
        this.empTpNm = empTpNm;
    }

    public String getCareer() {
        return career;
    }

    public void setCareer(String career) {
        this.career = career;
    }

    public String getMinEdubg() {
        return minEdubg;
    }

    public void setMinEdubg(String minEdubg) {
        this.minEdubg = minEdubg;
    }

    public String getSalAmt() {
        return salAmt;
    }

    public void setSalAmt(String salAmt) {
        this.salAmt = salAmt;
    }

    public String getSalTpNm() {
        return salTpNm;
    }

    public void setSalTpNm(String salTpNm) {
        this.salTpNm = salTpNm;
    }

    public String getRegion() {
        return region;
    }

    public void setRegion(String region) {
        this.region = region;
    }

    public String getCloseDt() {
        return closeDt;
    }

    public void setCloseDt(String closeDt) {
        this.closeDt = closeDt;
    }

    public String getWantedInfoUrl() {
        return wantedInfoUrl;
    }

    public void setWantedInfoUrl(String wantedInfoUrl) {
        this.wantedInfoUrl = wantedInfoUrl;
    }

    public String getBasicAddr() {
        return basicAddr;
    }

    public void setBasicAddr(String basicAddr) {
        this.basicAddr = basicAddr;
    }

    public String getDetailAddr() {
        return detailAddr;
    }

    public void setDetailAddr(String detailAddr) {
        this.detailAddr = detailAddr;
    }

    public String getInfoSvc() {
        return infoSvc;
    }

    public void setInfoSvc(String infoSvc) {
        this.infoSvc = infoSvc;
    }

    public String getJobCareerCd() {
        return jobCareerCd;
    }

    public void setJobCareerCd(String jobCareerCd) {
        this.jobCareerCd = jobCareerCd;
    }

    public String getJobAcdmcrCd() {
        return jobAcdmcrCd;
    }

    public void setJobAcdmcrCd(String jobAcdmcrCd) {
        this.jobAcdmcrCd = jobAcdmcrCd;
    }

    public String getJobEmpTpCd() {
        return jobEmpTpCd;
    }

    public void setJobEmpTpCd(String jobEmpTpCd) {
        this.jobEmpTpCd = jobEmpTpCd;
    }

    public String getJobAreaCd() {
        return jobAreaCd;
    }

    public void setJobAreaCd(String jobAreaCd) {
        this.jobAreaCd = jobAreaCd;
    }

    public String getJobabaCmmn276Cd() {
        return jobabaCmmn276Cd;
    }

    public void setJobabaCmmn276Cd(String jobabaCmmn276Cd) {
        this.jobabaCmmn276Cd = jobabaCmmn276Cd;
    }

    public String getJobabaCmmn274Cd() {
        return jobabaCmmn274Cd;
    }

    public void setJobabaCmmn274Cd(String jobabaCmmn274Cd) {
        this.jobabaCmmn274Cd = jobabaCmmn274Cd;
    }

    public String getUseYn() {
        return useYn;
    }

    public void setUseYn(String useYn) {
        this.useYn = useYn;
    }

    public String getDelYn() {
        return delYn;
    }

    public void setDelYn(String delYn) {
        this.delYn = delYn;
    }

    public String getLat() {
        return lat;
    }

    public void setLat(String lat) {
        this.lat = lat;
    }

    public String getLng() {
        return lng;
    }

    public void setLng(String lng) {
        this.lng = lng;
    }
}
