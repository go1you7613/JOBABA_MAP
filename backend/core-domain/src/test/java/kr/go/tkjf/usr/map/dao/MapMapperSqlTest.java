package kr.go.tkjf.usr.map.dao;

import kr.go.tkjf.usr.map.vo.MapSearchVO;
import org.apache.ibatis.builder.xml.XMLMapperBuilder;
import org.apache.ibatis.mapping.BoundSql;
import org.apache.ibatis.session.Configuration;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

class MapMapperSqlTest {

    private static final String MAPPER_RESOURCE = "kr/go/tkjf/usr/map/dao/sql/MapMapper.xml";
    private static Configuration configuration;

    @BeforeAll
    static void parseMapper() throws IOException {
        configuration = new Configuration();
        try (InputStream input = resourceStream()) {
            XMLMapperBuilder builder = new XMLMapperBuilder(
                    input, configuration, MAPPER_RESOURCE, configuration.getSqlFragments());
            builder.parse();
        }
    }

    @Test
    void salaryRangeUsesBoundParametersAndOverlapConditions() {
        MapSearchVO searchVO = viewportSearch();
        searchVO.setSalaryType("연봉");
        searchVO.setSalaryMin(3000L);
        searchVO.setSalaryMax(4000L);

        BoundSql boundSql = boundSql(searchVO);
        String sql = compact(boundSql.getSql());

        assertThat(sql).contains("REGEXP_SUBSTR", ">= ?", "<= ?");
        assertThat(parameterProperties(boundSql))
                .contains("salaryType", "salaryMin", "salaryMax");
    }

    @Test
    void salaryTypeOnlyDoesNotRequireNumericAmount() {
        MapSearchVO searchVO = viewportSearch();
        searchVO.setSalaryType("시급");

        BoundSql boundSql = boundSql(searchVO);

        assertThat(boundSql.getSql()).doesNotContain("REGEXP_SUBSTR");
        assertThat(parameterProperties(boundSql)).contains("salaryType");
        assertThat(parameterProperties(boundSql)).doesNotContain("salaryMin", "salaryMax");
    }

    @Test
    void salaryNoConditionOmitsAllSalaryPredicates() {
        MapSearchVO searchVO = viewportSearch();
        searchVO.setSalaryNoCondition(true);
        searchVO.setSalaryType("연봉");
        searchVO.setSalaryMin(3000L);
        searchVO.setSalaryMax(4000L);

        BoundSql boundSql = boundSql(searchVO);

        assertThat(boundSql.getSql()).doesNotContain("REGEXP_SUBSTR");
        assertThat(parameterProperties(boundSql))
                .doesNotContain("salaryType", "salaryMin", "salaryMax");
    }

    @Test
    void publicNcsFilterSupportsDirectPublicPortalCodes() {
        MapSearchVO searchVO = viewportSearch();
        searchVO.setSourceType("PUB");
        searchVO.setJobNcsCd(List.of("R600001", "R600002"));

        BoundSql boundSql = boundSql(searchVO);
        String sql = compact(boundSql.getSql());

        assertThat(sql)
                .contains("m.JOBABA_CD = j.JOBABA_CMMN_276_CD")
                .contains("FIND_IN_SET(?, REPLACE(COALESCE(j.JOBS_CD, ''), ' ', '')) > 0");
        assertThat(parameterProperties(boundSql).stream()
                .filter(property -> property.contains("code"))
                .count()).isEqualTo(4);
    }

    @Test
    void mapperKeepsCodesBoundAndAvoidsPrivateEmploymentFalseMappings() throws IOException {
        String mapperXml;
        try (InputStream input = resourceStream()) {
            mapperXml = new String(input.readAllBytes(), StandardCharsets.UTF_8);
        }

        assertThat(mapperXml).doesNotContain("${");
        assertThat(mapperXml).doesNotContain("PSN_CNT");
        assertThat(mapperXml).doesNotContain("CONCAT('R10', #{code}, '0')");
        assertThat(mapperXml)
                .contains("<foreach collection=\"jobCareerCd\" item=\"code\" separator=\" OR \">")
                .contains("<foreach collection=\"jobAcdmcrCd\" item=\"code\" separator=\" OR \">")
                .contains("<foreach collection=\"jobEmpTpCd\" item=\"code\" separator=\" OR \">")
                .contains("<foreach collection=\"prvCareerCd\" item=\"code\" separator=\" OR \">")
                .contains("<foreach collection=\"prvEduCd\" item=\"code\" separator=\" OR \">")
                .contains("<foreach collection=\"prvEmpTpCd\" item=\"code\" separator=\" OR \">")
                .contains("#{code} = '1' AND FIND_IN_SET('R1010'")
                .contains("#{code} = '2' AND FIND_IN_SET('R1020'")
                .contains("#{code} = '3' AND FIND_IN_SET('R1050'")
                .contains("#{code} = '3' AND FIND_IN_SET('R1060'")
                .contains("#{code} = '3' AND FIND_IN_SET('R1070'");
        assertThat(mapperXml.split("<include refid=\"jobSearchFilters\"/>", -1)).hasSize(3);
        assertThat(mapperXml)
                .contains("FROM jwrki.v_job_posting")
                .contains("jwrki.tb_empmn_map_coord")
                .contains("jwrki.tb_jobcls_ncs_map")
                .doesNotContain("FROM v_job_posting")
                .doesNotContain("FROM tb_empmn_map_coord")
                .doesNotContain("FROM tb_jobcls_ncs_map");
    }

    private static InputStream resourceStream() {
        return Objects.requireNonNull(
                MapMapperSqlTest.class.getClassLoader().getResourceAsStream(MAPPER_RESOURCE),
                "MapMapper.xml resource is missing");
    }

    private BoundSql boundSql(MapSearchVO searchVO) {
        return configuration.getMappedStatement("map.selectJobListByViewport").getBoundSql(searchVO);
    }

    private List<String> parameterProperties(BoundSql boundSql) {
        return boundSql.getParameterMappings().stream()
                .map(mapping -> mapping.getProperty())
                .collect(Collectors.toList());
    }

    private MapSearchVO viewportSearch() {
        MapSearchVO searchVO = new MapSearchVO();
        searchVO.setSwLat("36.6");
        searchVO.setSwLng("126.5");
        searchVO.setNeLat("38.3");
        searchVO.setNeLng("128.0");
        return searchVO;
    }

    private String compact(String sql) {
        return sql.replaceAll("\\s+", " ").trim();
    }
}
