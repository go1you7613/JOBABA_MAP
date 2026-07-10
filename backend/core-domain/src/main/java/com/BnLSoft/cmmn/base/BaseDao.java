package com.BnLSoft.cmmn.base;

import org.mybatis.spring.SqlSessionTemplate;

import javax.annotation.Resource;
import java.util.List;

public class BaseDao {

    @Resource
    private SqlSessionTemplate sqlSessionTemplate;

    protected List<?> list(String statement, Object parameter) {
        return sqlSessionTemplate.selectList(statement, parameter);
    }

    protected Object select(String statement, Object parameter) {
        return sqlSessionTemplate.selectOne(statement, parameter);
    }

    protected int insert(String statement, Object parameter) {
        return sqlSessionTemplate.insert(statement, parameter);
    }
}
