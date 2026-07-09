package kr.go.tkjf.usr.map.vo;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
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
    private List<@Pattern(regexp = "R6000(0[1-9]|1[0-9]|2[0-5])") String> jobNcsCd = new ArrayList<>();       // 직종코드  R6000: R600001~R600025
    private List<@Pattern(regexp = "R20(10|20|30|40)") String> jobCareerCd = new ArrayList<>();               // 경력코드  R2000: R2010=신입, R2020=경력, R2030=신입+경력, R2040=외국인전형
    private List<@Pattern(regexp = "R70(10|20|30|40|50|60|70)") String> jobAcdmcrCd = new ArrayList<>();       // 학력코드  R7000: R7010=학력무관 ~ R7070=박사
    private List<@Pattern(regexp = "R10(10|20|30|40|50|60|70)") String> jobEmpTpCd = new ArrayList<>();        // 고용형태  R1000: R1010=정규직 ~ R1070=청년인턴(채용형)

    // 민간 필터 (원천코드 기반 — jobkorea)
    private List<@Pattern(regexp = "[0-9]") String> prvJobCd = new ArrayList<>();      // 직종 대분류 CMMN_274: 0~9
    private List<@Pattern(regexp = "[1-4]") String> prvCareerCd = new ArrayList<>();   // 경력 GI_CAREER_CD: 1=신입, 2=경력, 3=신입/경력, 4=관계없음
    private List<@Pattern(regexp = "[03457]") String> prvEduCd = new ArrayList<>();    // 학력 GI_EDU_CUTLINE_CD: 0=학력무관, 3=고졸, 4=대졸2~3, 5=대졸4, 7=박사
    private List<@Pattern(regexp = "[12367]") String> prvEmpTpCd = new ArrayList<>();  // 고용형태 GI_JOB_TYPE_CD: 1=정규직, 2=계약직, 3=인턴직, 6=프리랜서, 7=아르바이트

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
}
