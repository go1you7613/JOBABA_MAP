<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <title>일자리 맵 | 잡아바</title>
    <link href="https://cdn.jsdelivr.net/npm/daisyui@5" rel="stylesheet" type="text/css">
    <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <link rel="stylesheet" href="/map/css/map.css?v=20260712-feature-request-v2">
</head>
<body data-theme="corporate">
<div id="app">

    <!-- ======================== 상단 검색 바 ======================== -->
    <header class="search-header">
        <div class="header-logo">
            <img class="logo-wordmark" src="/map/images/brand/jobaba-wordmark.svg" width="106" height="32" alt="" aria-hidden="true">
            <span class="logo-text">잡아바 일자리맵</span>
        </div>
    </header>

    <!-- ======================== 메인 레이아웃 ======================== -->
    <main class="main-layout">

        <!-- 모바일: 지도/목록 보기 전환 -->
        <div class="mobile-view-switch" role="tablist" aria-label="모바일 보기 전환">
            <button id="mobileMapViewBtn" type="button" class="mobile-view-btn is-active" role="tab" aria-selected="true" data-view="map">
                <i data-lucide="map" aria-hidden="true"></i>
                <span>지도보기</span>
            </button>
            <button id="mobileListViewBtn" type="button" class="mobile-view-btn" role="tab" aria-selected="false" data-view="list">
                <i data-lucide="list" aria-hidden="true"></i>
                <span>목록보기</span>
            </button>
        </div>

        <!-- PC: 좌측 채용공고 목록 패널 -->
        <aside id="jobPanel" class="job-panel">
            <div class="panel-search-section">
                <h2 class="panel-title">채용공고 검색</h2>
                <div class="panel-search-actions">
                    <div class="panel-search-wrap">
                        <input type="text" id="panelSearchInput" class="input input-bordered panel-search-input"
                               placeholder="직종, 기업명, 키워드 검색" maxlength="50" autocomplete="off">
                        <button id="panelSearchBtn" class="btn btn-ghost panel-search-btn" aria-label="채용공고 검색">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                            </svg>
                        </button>
                    </div>
                    <button id="panelAdvancedBtn" type="button" class="btn btn-primary panel-advanced-btn">
                        <span>상세검색</span>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>
                    </button>
                </div>
                <div class="source-type-tabs" role="tablist" aria-label="채용 채널 선택">
                    <button id="tabAll" class="src-tab src-tab-active" role="tab" aria-selected="true" data-src="">전체</button>
                    <button id="tabPub" class="src-tab" role="tab" aria-selected="false" data-src="PUB">공공채용</button>
                    <button id="tabPrv" class="src-tab" role="tab" aria-selected="false" data-src="PRV">민간채용</button>
                </div>
            </div>
            <div class="panel-header">
                <span id="jobCount" class="count-text">채용공고 조회 중...</span>
                <div class="dropdown dropdown-end sort-dropdown">
                    <button id="sortTypeBtn" type="button" tabindex="0" class="btn btn-sm sort-dropdown-btn" aria-label="정렬 기준">
                        <span id="sortTypeLabel">최신순</span>
                        <i class="sort-dropdown-icon" data-lucide="list-filter" aria-hidden="true"></i>
                    </button>
                    <ul class="dropdown-content menu sort-dropdown-menu bg-base-100 rounded-box shadow" role="menu">
                        <li><button type="button" class="sort-option is-active" data-sort="regDt" role="menuitem">최신순</button></li>
                        <li><button type="button" class="sort-option" data-sort="closeDt" role="menuitem">마감일순</button></li>
                        <li><button type="button" class="sort-option" data-sort="distance" role="menuitem">거리순</button></li>
                    </ul>
                </div>
            </div>
            <div id="recentSearches" class="recent-searches hidden">
                <div class="recent-header">
                    <span>최근 검색</span>
                    <button id="clearRecentBtn" class="btn btn-ghost btn-xs btn-text-sm">전체 삭제</button>
                </div>
                <ul id="recentList" class="recent-list"></ul>
            </div>
            <ul id="jobList" class="job-list" role="list" aria-label="채용공고 목록">
                <li class="skeleton-item"><div class="skeleton"></div></li>
                <li class="skeleton-item"><div class="skeleton"></div></li>
                <li class="skeleton-item"><div class="skeleton"></div></li>
            </ul>
            <div id="noResult" class="no-result hidden">
                <img class="no-result-character" src="/map/images/brand/jobaba-empty-state.svg" width="251" height="240" alt="" aria-hidden="true">
                <p>조건에 맞는 채용공고가 없습니다.</p>
                <p class="no-result-sub">지도를 이동하거나 조건을 변경해보세요.</p>
            </div>
        </aside>

        <!-- 지도 컨테이너 -->
        <div id="mapContainer" role="application" aria-label="채용공고 지도"></div>

        <!-- 지도 상단 오버레이 버튼 바 (고용24 스타일) -->
        <div class="map-top-bar">
            <span id="currentLocationName" class="map-location-label">경기도</span>
            <div class="map-top-actions">
                <button id="locationReselectBtn" class="btn btn-sm btn-map-top">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="10" r="3"/><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/></svg>
                    <span class="desktop-label">지역 선택</span><span class="mobile-label">지역</span>
                </button>
                <button id="nearMeJobsBtn" class="btn btn-sm btn-primary btn-map-top btn-map-top-accent">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/><line x1="12" y1="2" x2="12" y2="6"/><line x1="12" y1="18" x2="12" y2="22"/><line x1="2" y1="12" x2="6" y2="12"/><line x1="18" y1="12" x2="22" y2="12"/></svg>
                    <span class="desktop-label">현 위치 일자리 보기</span><span class="mobile-label">현 위치</span>
                </button>
                <select id="radiusSelect" class="select select-bordered select-sm radius-select" aria-label="검색 반경">
                    <option value="5">반경 5km</option>
                    <option value="10">반경 10km</option>
                    <option value="20">반경 20km</option>
                </select>
            </div>
        </div>

        <!-- 지도 범례 -->
        <div id="mapLegend" class="map-legend" aria-label="지도 범례">
            <div class="legend-section">
                <strong>채용유형</strong>
                <span><i class="legend-dot legend-public"></i>공공기관</span>
                <span><i class="legend-dot legend-private"></i>민간기업</span>
                <span><i class="legend-dot legend-mixed"></i>공공+민간</span>
            </div>
        </div>

        <!-- 지도 확대/축소 버튼 -->
        <div class="map-zoom-controls">
            <button id="zoomInBtn" class="btn btn-ghost btn-zoom" aria-label="확대">+</button>
            <div class="zoom-divider"></div>
            <button id="zoomOutBtn" class="btn btn-ghost btn-zoom" aria-label="축소">−</button>
        </div>

        <!-- GPS 현위치 버튼 -->
        <button id="myLocationBtn" class="btn btn-circle btn-my-location" aria-label="내 위치로 이동">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                <circle cx="12" cy="12" r="9"/>
                <circle cx="12" cy="12" r="3" fill="currentColor"/>
                <line x1="12" y1="2" x2="12" y2="5"/>
                <line x1="12" y1="19" x2="12" y2="22"/>
                <line x1="2" y1="12" x2="5" y2="12"/>
                <line x1="19" y1="12" x2="22" y2="12"/>
            </svg>
        </button>

    </main>

    <!-- ======================== 채용공고 상세 패널 ======================== -->
    <div id="jobDetail" class="job-detail hidden" role="complementary" aria-label="채용공고 상세">
        <div class="detail-header">
            <button id="detailCloseBtn" class="btn btn-circle btn-ghost btn-sm btn-close" aria-label="닫기">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                </svg>
            </button>
            <span>채용 상세</span>
        </div>
        <div id="detailContent" class="detail-content"></div>
    </div>

    <!-- ======================== 필터 모달 (검색 조건) ======================== -->
    <div id="filterModal" class="modal hidden" role="dialog" aria-modal="true" aria-labelledby="filterModalTitle">
        <div class="modal-overlay" id="filterOverlay"></div>
        <div class="modal-sheet modal-sheet-lg bg-base-100 shadow-xl">
            <div class="modal-header">
                <h2 id="filterModalTitle">검색 조건</h2>
                <button id="filterCloseBtn" class="btn btn-circle btn-ghost btn-sm btn-close" aria-label="필터 닫기">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                    </svg>
                </button>
            </div>
            <div class="modal-body modal-body-scroll">

                <!-- 모달 내 채널 탭 -->
                <div class="filter-src-tabs" role="tablist">
                    <button class="filter-src-tab filter-src-tab-active" data-src="PUB" role="tab" aria-selected="true">공공채용</button>
                    <button class="filter-src-tab" data-src="PRV" role="tab" aria-selected="false">민간채용</button>
                </div>

                <!-- ===== 공공채용 필터 섹션 ===== -->
                <div id="filterSectionPub" class="filter-section">

                    <!-- 직종(NCS) -->
                    <div class="filter-row">
                        <span class="filter-label-col">직종(NCS)</span>
                        <div class="filter-val-col filter-col3">
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="" id="pubNcsAll" checked> 전체</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600001"> 사업관리</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600002"> 경영.회계.사무</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600003"> 금융.보험</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600004"> 교육.자연.사회과학</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600005"> 법률.경찰.소방.교도.국방</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600006"> 보건.의료</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600007"> 사회복지.종교</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600008"> 문화.예술.디자인.방송</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600009"> 운전.운송</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600010"> 영업판매</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600011"> 경비.청소</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600012"> 이용.숙박.여행.오락.스포츠</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600013"> 음식서비스</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600014"> 건설</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600015"> 기계</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600016"> 재료</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600017"> 화학</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600018"> 섬유.의복</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600019"> 전기.전자</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600020"> 정보통신</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600021"> 식품가공</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600022"> 인쇄.목재.가구.공예</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600023"> 환경.에너지.안전</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600024"> 농림어업</label>
                            <label class="cb-label"><input type="checkbox" name="pubNcs" value="R600025"> 연구</label>
                        </div>
                    </div>

                    <!-- 고용형태 -->
                    <div class="filter-row">
                        <span class="filter-label-col">고용형태</span>
                        <div class="filter-val-col filter-col2">
                            <label class="cb-label"><input type="checkbox" name="pubEmpTp" value="" id="pubEmpTpAll" checked> 전체</label>
                            <label class="cb-label"><input type="checkbox" name="pubEmpTp" value="R1010"> 정규직</label>
                            <label class="cb-label"><input type="checkbox" name="pubEmpTp" value="R1020"> 계약직</label>
                            <label class="cb-label"><input type="checkbox" name="pubEmpTp" value="R1030"> 무기계약직</label>
                            <label class="cb-label"><input type="checkbox" name="pubEmpTp" value="R1040"> 비정규직</label>
                            <label class="cb-label"><input type="checkbox" name="pubEmpTp" value="R1050"> 청년인턴</label>
                            <label class="cb-label"><input type="checkbox" name="pubEmpTp" value="R1060"> 청년인턴(체험형)</label>
                            <label class="cb-label"><input type="checkbox" name="pubEmpTp" value="R1070"> 청년인턴(채용형)</label>
                        </div>
                    </div>

                    <!-- 경력 -->
                    <div class="filter-row">
                        <span class="filter-label-col">경력</span>
                        <div class="filter-val-col">
                            <label class="cb-label"><input type="checkbox" name="pubCareer" value="" id="pubCareerAll" checked> 전체</label>
                            <label class="cb-label"><input type="checkbox" name="pubCareer" value="R2010"> 신입</label>
                            <label class="cb-label"><input type="checkbox" name="pubCareer" value="R2020"> 경력</label>
                            <label class="cb-label"><input type="checkbox" name="pubCareer" value="R2030"> 신입+경력</label>
                            <label class="cb-label"><input type="checkbox" name="pubCareer" value="R2040"> 외국인 전형</label>
                        </div>
                    </div>

                    <!-- 학력 -->
                    <div class="filter-row filter-edu-row filter-row-last">
                        <span class="filter-label-col">학력</span>
                        <div class="filter-val-col filter-col2">
                            <label class="cb-label"><input type="checkbox" name="pubEdu" value="" id="pubEduAll" checked> 전체</label>
                            <label class="cb-label"><input type="checkbox" name="pubEdu" value="R7010"> 학력무관</label>
                            <label class="cb-label"><input type="checkbox" name="pubEdu" value="R7020"> 중졸이하</label>
                            <label class="cb-label"><input type="checkbox" name="pubEdu" value="R7030"> 고졸</label>
                            <label class="cb-label"><input type="checkbox" name="pubEdu" value="R7040"> 대졸(2~3년)</label>
                            <label class="cb-label"><input type="checkbox" name="pubEdu" value="R7050"> 대졸(4년)</label>
                            <label class="cb-label"><input type="checkbox" name="pubEdu" value="R7060"> 석사</label>
                            <label class="cb-label"><input type="checkbox" name="pubEdu" value="R7070"> 박사</label>
                        </div>
                    </div>

                </div><!-- /filterSectionPub -->

                <!-- ===== 민간채용 필터 섹션 ===== -->
                <div id="filterSectionPrv" class="filter-section hidden">

                    <!-- 직종 대분류 -->
                    <div class="filter-row filter-edu-row">
                        <span class="filter-label-col">직종</span>
                        <div class="filter-val-col filter-col2">
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="" id="prvJobAll" checked> 전체</label>
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="0"> 경영ㆍ사무ㆍ금융ㆍ보험직</label>
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="1"> 연구직 및 공학 기술직</label>
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="2"> 교육ㆍ법률ㆍ사회복지ㆍ경찰ㆍ소방직</label>
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="3"> 보건ㆍ의료직</label>
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="4"> 예술ㆍ디자인ㆍ방송ㆍ스포츠직</label>
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="5"> 미용ㆍ여행ㆍ숙박ㆍ음식ㆍ경비ㆍ청소직</label>
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="6"> 영업ㆍ판매ㆍ운전ㆍ운송직</label>
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="7"> 건설ㆍ채굴직</label>
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="8"> 설치ㆍ정비ㆍ생산직</label>
                            <label class="cb-label"><input type="checkbox" name="prvJob" value="9"> 농림어업직</label>
                        </div>
                    </div>

                    <!-- 고용형태 -->
                    <div class="filter-row">
                        <span class="filter-label-col">고용형태</span>
                        <div class="filter-val-col filter-col2">
                            <label class="cb-label"><input type="checkbox" name="prvEmpTp" value="" id="prvEmpTpAll" checked> 전체</label>
                            <label class="cb-label"><input type="checkbox" name="prvEmpTp" value="1"> 정규직</label>
                            <label class="cb-label"><input type="checkbox" name="prvEmpTp" value="2"> 계약직</label>
                            <label class="cb-label"><input type="checkbox" name="prvEmpTp" value="3"> 인턴직</label>
                            <label class="cb-label"><input type="checkbox" name="prvEmpTp" value="6"> 프리랜서</label>
                            <label class="cb-label"><input type="checkbox" name="prvEmpTp" value="7"> 아르바이트</label>
                        </div>
                    </div>

                    <!-- 경력 -->
                    <div class="filter-row">
                        <span class="filter-label-col">경력</span>
                        <div class="filter-val-col">
                            <label class="cb-label"><input type="checkbox" name="prvCareer" value="" id="prvCareerAll" checked> 전체</label>
                            <label class="cb-label"><input type="checkbox" name="prvCareer" value="1"> 신입</label>
                            <label class="cb-label"><input type="checkbox" name="prvCareer" value="2"> 경력</label>
                            <label class="cb-label"><input type="checkbox" name="prvCareer" value="3"> 신입/경력</label>
                            <label class="cb-label"><input type="checkbox" name="prvCareer" value="4"> 관계없음</label>
                        </div>
                    </div>

                    <!-- 학력 -->
                    <div class="filter-row">
                        <span class="filter-label-col">학력</span>
                        <div class="filter-val-col filter-col2">
                            <label class="cb-label"><input type="checkbox" name="prvEdu" value="" id="prvEduAll" checked> 전체</label>
                            <label class="cb-label"><input type="checkbox" name="prvEdu" value="0"> 학력무관</label>
                            <label class="cb-label"><input type="checkbox" name="prvEdu" value="3"> 고졸</label>
                            <label class="cb-label"><input type="checkbox" name="prvEdu" value="4"> 대졸(2~3년)</label>
                            <label class="cb-label"><input type="checkbox" name="prvEdu" value="5"> 대졸(4년)</label>
                            <label class="cb-label"><input type="checkbox" name="prvEdu" value="7"> 박사</label>
                        </div>
                    </div>

                    <!-- 희망임금 -->
                    <div class="filter-row filter-row-last">
                        <span class="filter-label-col">희망임금</span>
                        <div class="filter-salary" id="salaryFilter">
                            <label class="salary-type-field" for="salaryType">
                                <span>유형</span>
                                <select id="salaryType" name="salaryType" class="select select-bordered select-sm sel-sal">
                                    <option value="연봉">연봉</option>
                                    <option value="월급">월급</option>
                                    <option value="일급">일급</option>
                                    <option value="시급">시급</option>
                                </select>
                            </label>
                            <div class="salary-range">
                                <label class="salary-range-field" for="salaryMin">
                                    <span>최소</span>
                                    <span class="salary-input-wrap">
                                        <input id="salaryMin" name="salaryMin" class="input input-bordered input-sm input-sal" type="number" min="0" step="1" inputmode="numeric" placeholder="최소">
                                        <span id="salaryMinUnit" class="salary-unit">만원</span>
                                    </span>
                                </label>
                                <label class="salary-range-field" for="salaryMax">
                                    <span>최대</span>
                                    <span class="salary-input-wrap">
                                        <input id="salaryMax" name="salaryMax" class="input input-bordered input-sm input-sal" type="number" min="0" step="1" inputmode="numeric" placeholder="최대">
                                        <span id="salaryMaxUnit" class="salary-unit">만원</span>
                                    </span>
                                </label>
                            </div>
                            <label class="cb-label salary-no-condition"><input type="checkbox" id="salaryNoCondition" name="salaryNoCondition" checked> 조건 없음</label>
                        </div>
                    </div>

                </div><!-- /filterSectionPrv -->

            </div>
            <div class="modal-footer filter-footer">
                <div id="filterSummary" class="filter-summary">검색조건을 선택해 주세요.</div>
                <div class="filter-footer-btns">
                    <button id="filterResetBtn" class="btn btn-outline btn-secondary">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 .49-3.93"/></svg>
                        초기화
                    </button>
                    <button id="filterApplyBtn" class="btn btn-primary">적용</button>
                </div>
            </div>
        </div>
    </div>

    <!-- ======================== 위치 재선택 모달 ======================== -->
    <div id="locationReselectModal" class="modal hidden" role="dialog" aria-modal="true" aria-labelledby="locReselectTitle">
        <div class="modal-overlay" id="locReselectOverlay"></div>
        <div class="modal-sheet modal-sheet-lg bg-base-100 shadow-xl">
            <div class="modal-header">
                <h2 id="locReselectTitle">위치 재선택</h2>
                <button id="locReselectCloseBtn" class="btn btn-circle btn-ghost btn-sm btn-close" aria-label="닫기">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                    </svg>
                </button>
            </div>
            <!-- 탭 -->
            <div class="loc-tabs">
                <button class="tab loc-tab active" data-tab="region">지역별</button>
                <button class="tab loc-tab" data-tab="subway">역세권별</button>
            </div>
            <!-- 지역별 탭 -->
            <div id="tabRegion" class="loc-tab-content">
                <div class="region-grid">
                    <div class="region-col region-sido">
                        <ul id="sidoList" class="region-list"></ul>
                    </div>
                    <div class="region-col region-sigungu">
                        <ul id="sigunguList" class="region-list"></ul>
                    </div>
                </div>
            </div>
            <!-- 역세권별 탭 -->
            <div id="tabSubway" class="loc-tab-content hidden">
                <div class="subway-selects">
                    <select id="subwayCitySelect" class="select select-bordered select-sm sel-subway">
                        <option value="">도시 선택</option>
                    </select>
                    <select id="subwayLineSelect" class="select select-bordered select-sm sel-subway">
                        <option value="">호선 선택</option>
                    </select>
                </div>
                <div id="stationGrid" class="station-grid"></div>
            </div>
            <div class="modal-footer">
                <button id="locReselectCancelBtn" class="btn btn-outline btn-secondary">취소</button>
                <button id="locReselectApplyBtn" class="btn btn-primary">적용</button>
            </div>
        </div>
    </div>

    <!-- ======================== 최초 위치 안내 모달 (S-02) ======================== -->
    <div id="locationModal" class="modal" role="dialog" aria-modal="true" aria-labelledby="locationModalTitle">
        <div class="modal-overlay"></div>
        <div class="modal-sheet modal-center bg-base-100 shadow-xl">
            <div class="modal-character" aria-hidden="true">
                <img class="modal-character-base" src="/map/images/brand/jobaba-onboarding-base.svg" alt="">
                <img class="modal-character-overlay" src="/map/images/brand/jobaba-onboarding-overlay.svg" alt="">
            </div>
            <h2 id="locationModalTitle">내 주변 일자리를 찾아볼까요?</h2>
            <p class="modal-desc">위치 정보를 허용하면 현재 위치 주변의<br>채용공고를 바로 확인할 수 있습니다.</p>
            <div class="modal-footer">
                <button id="locationDenyBtn" class="btn btn-outline btn-secondary">나중에</button>
                <button id="locationAllowBtn" class="btn btn-primary">위치 허용</button>
            </div>
        </div>
    </div>

    <!-- 로딩 스피너 -->
    <div id="loadingOverlay" class="loading-overlay hidden" aria-hidden="true">
        <div class="spinner"></div>
    </div>

    <!-- 토스트 메시지 -->
    <div id="toast" class="toast hidden" role="alert" aria-live="polite"></div>

</div><!-- /#app -->

<script>
    window.JobabaMapConfig = {
        apiBaseUrl: '<c:out value="${jobabaMapApiBaseUrl}" />'
    };
</script>
<script src="/map/js/kakao-key.js?v=20260629-closed-fix"></script>
<script src="/map/js/map-location-data.js?v=20260629-closed-fix"></script>
<script src="/map/js/map.js?v=20260712-feature-request-v2"></script>
</body>
</html>
