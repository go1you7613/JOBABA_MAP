package kr.go.tkjf.usr.map.vo;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;

import javax.validation.Validation;
import javax.validation.Validator;
import javax.validation.ValidatorFactory;

import static org.assertj.core.api.Assertions.assertThat;

class MapSearchVOTest {

    private static final ValidatorFactory VALIDATOR_FACTORY = Validation.buildDefaultValidatorFactory();
    private static final Validator VALIDATOR = VALIDATOR_FACTORY.getValidator();

    @Test
    void acceptsValidSalaryRange() {
        MapSearchVO searchVO = new MapSearchVO();
        searchVO.setSalaryType("월급");
        searchVO.setSalaryMin(250L);
        searchVO.setSalaryMax(350L);

        assertThat(VALIDATOR.validate(searchVO)).isEmpty();
    }

    @Test
    void rejectsInvalidSalaryRange() {
        MapSearchVO searchVO = new MapSearchVO();
        searchVO.setSalaryType("월급");
        searchVO.setSalaryMin(350L);
        searchVO.setSalaryMax(250L);

        assertThat(VALIDATOR.validate(searchVO)).isNotEmpty();
    }

    @Test
    void salaryNoConditionIgnoresOtherSalaryValues() {
        MapSearchVO searchVO = new MapSearchVO();
        searchVO.setSalaryNoCondition(true);
        searchVO.setSalaryType("주급");
        searchVO.setSalaryMin(-1L);
        searchVO.setSalaryMax(-2L);

        assertThat(VALIDATOR.validate(searchVO)).isEmpty();
    }

    @AfterAll
    static void closeValidatorFactory() {
        VALIDATOR_FACTORY.close();
    }
}
