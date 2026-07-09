package kr.go.tkjf.usr.map.vo;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

@Getter
@Setter
@NoArgsConstructor
public class JobPostingVO {

    // 공고 식별
    private String wantedAuthNo;   // PK
    private String source;         // 채널명 (공공기관 | 잡코리아 | …)
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

    // 통합 필터 컬럼 (JOB_ 계열 — R코드)
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
}
