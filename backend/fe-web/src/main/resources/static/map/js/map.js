/**
 * 일자리 맵 — map.js
 */
(function () {
    'use strict';

    var LOCATION_DATA = window.JobabaMapLocationData || { REGION_DATA: {}, SUBWAY_DATA: {} };
    var REGION_DATA = LOCATION_DATA.REGION_DATA;
    var SUBWAY_DATA = LOCATION_DATA.SUBWAY_DATA;

    /* ─── 상태 ─── */
    var state = {
        map: null,
        markers: [],
        selectedMarker: null,
        userLat: null, userLng: null,
        keyword: '',
        sourceType: '',             // ''=전체 / PUB=공공 / PRV=민간
        // 공공 필터 (R코드)
        pubNcsCds: [],
        pubEmpTpCds: [],
        pubCareerCds: [],
        pubEduCds: [],
        // 민간 필터 (원천코드)
        prvJobCds: [],
        prvEmpTpCds: [],
        prvCareerCds: [],
        prvEduCds: [],
        salaryType: '',
        salaryMin: '',
        salaryMax: '',
        salaryNoCondition: true,
        sortType: 'regDt',
        loading: false,
        pendingLoad: false,
        filterCount: 0,
        markerPopoverEl: null,
        radiusKm: 5,
        currentJobs: [],
        currentMarkerJobs: [],
        totalJobCount: 0,
        currentJobPage: 1,
        hasMoreJobs: true,
        loadingMoreJobs: false,
        mapReady: false,
        mapFailed: false,
        suppressIdleLoadUntil: 0,
        mobileListMapViewport: null,
        locationLabelOverride: '',
        // 위치 재선택
        selectedSido: '',
        selectedSigungu: '',
        selectedStation: null,
        geocodeInFlight: false,
        geocodeSkippedIds: {},
        geocodeSavedIds: {}
    };

    var RECENT_KEY = 'jobaba_map_recent';
    var MAX_RECENT = 8;
    var JOB_PAGE_SIZE = 20;
    var MARKER_PAGE_SIZE = 200;
    var LIST_SCROLL_THRESHOLD = 160;
    var GEOCODE_BATCH_SIZE = 20;
    var DEFAULT_LAT = 37.4138, DEFAULT_LNG = 127.5183;
    var DEFAULT_LEVEL = 7;
    var KAKAO_JS_KEY = window.JobabaMapKakaoKey.selectKakaoJsKey(window.location.href);
    var COMMON_CODES = {
        // 공공 (R코드)
        career: { R2010: '신입', R2020: '경력', R2030: '신입+경력', R2040: '외국인전형' },
        empTp:  { R1010: '정규직', R1020: '계약직', R1030: '무기계약직', R1040: '비정규직',
                  R1050: '청년인턴', R1060: '청년인턴(체험형)', R1070: '청년인턴(채용형)' },
        edubg:  { R7010: '학력무관', R7020: '중졸이하', R7030: '고졸', R7040: '대졸(2~3년)',
                  R7050: '대졸(4년)', R7060: '석사', R7070: '박사' },
        ncs:    { R600001: '사업관리', R600002: '경영.회계.사무', R600003: '금융.보험',
                  R600004: '교육.자연.사회과학', R600005: '법률.경찰.소방.교도.국방',
                  R600006: '보건.의료', R600007: '사회복지.종교', R600008: '문화.예술.디자인.방송',
                  R600009: '운전.운송', R600010: '영업판매', R600011: '경비.청소',
                  R600012: '이용.숙박.여행.오락.스포츠', R600013: '음식서비스', R600014: '건설',
                  R600015: '기계', R600016: '재료', R600017: '화학', R600018: '섬유.의복',
                  R600019: '전기.전자', R600020: '정보통신', R600021: '식품가공',
                  R600022: '인쇄.목재.가구.공예', R600023: '환경.에너지.안전',
                  R600024: '농림어업', R600025: '연구' },
        // 민간 ((신)잡아바_분류체계)
        prvJob:    { '0': '경영ㆍ사무ㆍ금융ㆍ보험직', '1': '연구직 및 공학 기술직',
                     '2': '교육ㆍ법률ㆍ사회복지ㆍ경찰ㆍ소방직 및 군인', '3': '보건ㆍ의료직',
                     '4': '예술ㆍ디자인ㆍ방송ㆍ스포츠직', '5': '미용ㆍ여행ㆍ숙박ㆍ음식ㆍ경비ㆍ청소직',
                     '6': '영업ㆍ판매ㆍ운전ㆍ운송직', '7': '건설ㆍ채굴직',
                     '8': '설치ㆍ정비ㆍ생산직', '9': '농림어업직' },
        prvEmpTp:  { '1': '정규직', '2': '계약직', '3': '인턴직', '6': '프리랜서', '7': '아르바이트' },
        prvCareer: { '1': '신입', '2': '경력', '3': '신입/경력', '4': '관계없음' },
        prvEdu:    { '0': '학력무관', '3': '고졸', '4': '대졸(2~3년)', '5': '대졸(4년)', '7': '박사' }
    };

    var NCS_JOBABA_276 = {
        R600002: ['021','022','023','024','025','026','027','028','029'],
        R600003: ['031','032','033'],
        R600004: ['110','121','122','211','212','213','214','215'],
        R600005: ['221','222','240','250'],
        R600006: ['301','302','303','304','305','306','307'],
        R600007: ['231','232','233'],
        R600008: ['411','412','413','414','415','416','417'],
        R600009: ['621','622','623','624'],
        R600010: ['611','612','613','614','615','616','617'],
        R600011: ['541','542','561','562'],
        R600012: ['420','511','512','521','522','523','524'],
        R600013: ['531','532'],
        R600014: ['140','701','702','703','704','705','706'],
        R600015: ['151','811','812','813','814','815','816','817'],
        R600016: ['152','821','822','823','824','825','826'],
        R600017: ['154','851','852'],
        R600018: ['156','861','862','863','864'],
        R600019: ['153','831','832','833','834','835','836'],
        R600020: ['131','132','133','134','135','136','841','842'],
        R600021: ['157','871','872','873'],
        R600022: ['159','881','882','883','884','885'],
        R600023: ['155','158','853'],
        R600024: ['901','902','903','904','905'],
        R600025: ['110','121','122']
    };

    function apiUrl(path) {
        return path;
    }

    /* ─── DOM ─── */
    var $ = function (id) { return document.getElementById(id); };
    var $searchInput    = $('searchInput');
    var $searchBtn      = $('searchBtn');
    var $panelSearchInput = $('panelSearchInput');
    var $panelSearchBtn   = $('panelSearchBtn');
    var $sortTypeBtn    = $('sortTypeBtn');
    var $sortTypeLabel  = $('sortTypeLabel');
    var $mobileMapViewBtn  = $('mobileMapViewBtn');
    var $mobileListViewBtn = $('mobileListViewBtn');
    var $mainLayout     = document.querySelector('.main-layout');
    var $jobPanel       = $('jobPanel');
    var $jobCount       = $('jobCount');
    var $jobList        = $('jobList');
    var $noResult       = $('noResult');
    var $jobDetail      = $('jobDetail');
    var $detailContent  = $('detailContent');
    var $detailCloseBtn = $('detailCloseBtn');
    var $myLocationBtn  = $('myLocationBtn');
    var $filterBtn      = $('filterBtn');
    var $filterBtn2     = $('filterBtn2');
    var $filterBadge    = $('filterBadge');
    var $filterModal    = $('filterModal');
    var $filterOverlay  = $('filterOverlay');
    var $filterCloseBtn = $('filterCloseBtn');
    var $filterResetBtn = $('filterResetBtn');
    var $filterApplyBtn = $('filterApplyBtn');
    var $filterSummary  = $('filterSummary');
    var $locationModal  = $('locationModal');
    var $locationAllowBtn = $('locationAllowBtn');
    var $locationDenyBtn  = $('locationDenyBtn');
    var $loadingOverlay = $('loadingOverlay');
    var $toast          = $('toast');
    var $recentSearches = $('recentSearches');
    var $recentList     = $('recentList');
    var $clearRecentBtn = $('clearRecentBtn');
    var $currentLocationName = $('currentLocationName');
    var $locationReselectBtn = $('locationReselectBtn');
    var $nearMeJobsBtn       = $('nearMeJobsBtn');
    var $radiusSelect        = $('radiusSelect');
    var $panelJobBtn         = $('panelJobBtn');
    var $panelCareerSelect   = $('panelCareerSelect');
    var $panelEmpSelect      = $('panelEmpSelect');
    var $panelEduSelect      = $('panelEduSelect');
    var $panelAdvancedBtn    = $('panelAdvancedBtn');
    var $zoomInBtn  = $('zoomInBtn');
    var $zoomOutBtn = $('zoomOutBtn');
    var $locReselectModal     = $('locationReselectModal');
    var $locReselectOverlay   = $('locReselectOverlay');
    var $locReselectCloseBtn  = $('locReselectCloseBtn');
    var $locReselectCancelBtn = $('locReselectCancelBtn');
    var $locReselectApplyBtn  = $('locReselectApplyBtn');
    var $sidoList      = $('sidoList');
    var $sigunguList   = $('sigunguList');
    var $subwayCitySelect = $('subwayCitySelect');
    var $subwayLineSelect = $('subwayLineSelect');
    var $stationGrid   = $('stationGrid');
    var $salaryFilter = $('salaryFilter');
    var $salaryType = $('salaryType');
    var $salaryMin = $('salaryMin');
    var $salaryMax = $('salaryMax');
    var $salaryMinUnit = $('salaryMinUnit');
    var $salaryMaxUnit = $('salaryMaxUnit');
    var $salaryNoCondition = $('salaryNoCondition');

    document.querySelectorAll('input[type="checkbox"]').forEach(function (input) {
        if (input.closest('.filter-checkbox-row')) return;
        input.classList.add('checkbox', 'checkbox-primary', 'checkbox-xs');
    });

    function loadKakaoSdk() {
        return new Promise(function (resolve, reject) {
            if (window.kakao && window.kakao.maps) {
                resolve();
                return;
            }

            var done = false;
            var script = document.createElement('script');
            script.src = 'https://dapi.kakao.com/v2/maps/sdk.js?appkey=' + KAKAO_JS_KEY + '&libraries=services&autoload=false';
            script.async = true;
            script.onload = function () {
                if (done) return;
                if (window.kakao && kakao.maps && typeof kakao.maps.load === 'function') {
                    kakao.maps.load(function () {
                        if (done) return;
                        done = true;
                        resolve();
                    });
                    return;
                }
                done = true;
                reject(new Error('Kakao Maps loader is unavailable'));
            };
            script.onerror = function () {
                if (done) return;
                done = true;
                reject(new Error('Kakao Maps SDK load failed'));
            };
            document.head.appendChild(script);

            setTimeout(function () {
                if (done) return;
                done = true;
                reject(new Error('Kakao Maps SDK load timeout'));
            }, 4500);
        });
    }

    /* ─── 지도 초기화 ─── */
    function initMap(lat, lng, level) {
        var center = new kakao.maps.LatLng(lat || DEFAULT_LAT, lng || DEFAULT_LNG);
        state.map = new kakao.maps.Map($('mapContainer'), {
            center: center,
            level: level || DEFAULT_LEVEL
        });
        state.mapReady = true;
        // idle 이벤트마다 자동 재검색 (고용24 방식)
        kakao.maps.event.addListener(state.map, 'idle', function () {
            if (Date.now() < state.suppressIdleLoadUntil) {
                return;
            }
            if ($mainLayout && $mainLayout.classList.contains('mobile-list-view')) return;
            loadJobs();
        });
        kakao.maps.event.addListener(state.map, 'dragstart', function () {
            state.suppressIdleLoadUntil = 0;
            state.locationLabelOverride = '';
        });
        loadJobs();
    }

    function initMapFallback() {
        state.mapFailed = true;
        state.mapReady = false;
        state.map = null;
        $('mapContainer').classList.add('map-unavailable');
        $('mapContainer').innerHTML =
            '<div class="local-map-layer" aria-label="로컬 좌표 지도">' +
                '<div class="local-map-grid"></div>' +
                '<div id="localMarkers" class="local-markers"></div>' +
                '<div class="local-map-notice">' +
                    '<p class="map-fallback-title">로컬 지도 모드</p>' +
                    '<p class="map-fallback-desc">카카오맵 SDK 연결 전까지 좌표 기반 마커로 표시합니다.</p>' +
                '</div>' +
            '</div>';
        loadJobs();
    }

    function getSearchBounds() {
        if (state.mapReady && state.map) {
            var mapBounds = state.map.getBounds();
            var sw = mapBounds.getSouthWest();
            var ne = mapBounds.getNorthEast();
            return {
                swLat: sw.getLat(),
                swLng: sw.getLng(),
                neLat: ne.getLat(),
                neLng: ne.getLng()
            };
        }
        return {
            swLat: 36.6,
            swLng: 126.5,
            neLat: 38.3,
            neLng: 128.0
        };
    }

    /* ─── 채용공고 로드 ─── */
    function loadJobs() {
        if (state.loading) {
            state.pendingLoad = true;
            return;
        }
        state.currentJobPage = 1;
        state.hasMoreJobs = true;
        state.loadingMoreJobs = false;
        state.loading = true;
        state.pendingLoad = false;
        showListUpdating(true);

        var bounds = getSearchBounds();
        var params = buildJobSearchParams(bounds, state.currentJobPage);

        fetch(apiUrl('/api/v1/map/jobs?' + params))
            .then(parseJobListResponse)
            .then(function (result) {
                var data = prepareJobsForDisplay(result.data);
                state.totalJobCount = getTotalJobCount(result.totalCount, data.length);
                state.hasMoreJobs = data.length < state.totalJobCount;
                return loadMarkerJobs(bounds, data).then(function (markerData) {
                    renderJobResults(data, bounds, markerData);
                    geocodeMissingJobs(params);
                });
            })
            .catch(function () {
                state.hasMoreJobs = false;
                state.currentJobs = [];
                state.currentMarkerJobs = [];
                state.totalJobCount = 0;
                showToast('데이터를 불러오지 못했습니다.');
                renderJobList([]);
            })
            .finally(function () {
                state.loading = false;
                showListUpdating(false);
                if (state.pendingLoad) loadJobs();
            });
    }

    function buildJobSearchParams(bounds, page, options) {
        options = options || {};
        var sourceType = options.sourceType !== undefined ? options.sourceType : state.sourceType;
        var size = options.size || JOB_PAGE_SIZE;
        var params = new URLSearchParams({
            swLat: bounds.swLat, swLng: bounds.swLng,
            neLat: bounds.neLat, neLng: bounds.neLng,
            page: page || 1, size: size,
            sortType: state.sortType === 'distance' ? 'regDt' : state.sortType
        });
        if (state.keyword) params.append('keyword', state.keyword);
        if (sourceType === 'PUB' || sourceType === 'PRV') {
            params.append('sourceType', sourceType);
        }
        appendActiveServerFilters(params, sourceType);
        return params;
    }

    function appendActiveServerFilters(params, sourceType) {
        if (sourceType === 'PUB') {
            appendAllParams(params, 'jobNcsCd', state.pubNcsCds);
            appendAllParams(params, 'jobEmpTpCd', state.pubEmpTpCds);
            appendAllParams(params, 'jobCareerCd', state.pubCareerCds);
            appendAllParams(params, 'jobAcdmcrCd', state.pubEduCds);
        } else if (sourceType === 'PRV') {
            appendAllParams(params, 'prvEmpTpCd', state.prvEmpTpCds);
            appendAllParams(params, 'prvCareerCd', state.prvCareerCds);
            appendAllParams(params, 'prvEduCd', state.prvEduCds);
            appendAllParams(params, 'prvJobCd', state.prvJobCds);
            appendSalaryParams(params);
        }
    }

    function appendAllParams(params, name, values) {
        values.forEach(function (value) {
            params.append(name, value);
        });
    }

    function appendSalaryParams(params) {
        params.append('salaryNoCondition', state.salaryNoCondition ? 'true' : 'false');
        if (state.salaryNoCondition) return;
        if (state.salaryType) params.append('salaryType', state.salaryType);
        if (state.salaryMin !== '') params.append('salaryMin', state.salaryMin);
        if (state.salaryMax !== '') params.append('salaryMax', state.salaryMax);
    }

    function prepareJobsForDisplay(data) {
        var jobs = applyClientFilters(data);
        if (state.sortType !== 'distance') return jobs;

        var base = getDistanceBase();
        jobs.sort(function (a, b) {
            return distance(base.lat, base.lng, a.lat, a.lng)
                 - distance(base.lat, base.lng, b.lat, b.lng);
        });
        return jobs;
    }

    function loadMarkerJobs(bounds, listData) {
        var sourceTypes = state.sourceType ? [state.sourceType] : ['PUB', 'PRV'];
        var requests = sourceTypes.map(function (sourceType) {
            var params = buildJobSearchParams(bounds, 1, {
                sourceType: sourceType,
                size: MARKER_PAGE_SIZE
            });
            return fetch(apiUrl('/api/v1/map/jobs?' + params))
                .then(parseJobListResponse)
                .then(function (result) {
                    return prepareJobsForDisplay(result.data);
                });
        });

        return Promise.all(requests)
            .then(function (groups) {
                return mergeUniqueJobs([listData].concat(groups).reduce(function (all, group) {
                    return all.concat(group || []);
                }, []));
            })
            .catch(function () {
                return listData;
            });
    }

    function mergeUniqueJobs(jobs) {
        var seen = {};
        return (jobs || []).filter(function (job) {
            if (!job || !job.wantedAuthNo || seen[job.wantedAuthNo]) return false;
            seen[job.wantedAuthNo] = true;
            return true;
        });
    }

    function getDistanceBase() {
        var baseLat = state.userLat;
        var baseLng = state.userLng;
        if ((!baseLat || !baseLng) && state.mapReady && state.map) {
            var center = state.map.getCenter();
            baseLat = center.getLat();
            baseLng = center.getLng();
        }
        return { lat: baseLat, lng: baseLng };
    }

    function getDisplayJobMeta(job) {
        return {
            empTpNm: getDisplayEmploymentType(job),
            career: getDisplayCareer(job),
            minEdubg: getDisplayEducation(job),
            jobsNm: getDisplayJobName(job)
        };
    }

    function getDisplayEmploymentType(job) {
        var label = getCodeLabels(job, 'empTp', 'prvEmpTp', job.jobEmpTpCd);
        if (label) return label;
        var text = cleanDisplayText(job.empTpNm);
        if (!text) return '';
        if (text.indexOf('기간의 정함이 없는 근로계약') !== -1) return '정규직';
        if (text.indexOf('기간의 정함이 있는 근로계약') !== -1) return '계약직';
        return shortenDisplayText(text, 18);
    }

    function getDisplayCareer(job) {
        if (hasReadableText(job.career)) return cleanDisplayText(job.career);
        return getCodeLabels(job, 'career', 'prvCareer', job.career || job.jobCareerCd);
    }

    function getDisplayEducation(job) {
        if (hasReadableText(job.minEdubg)) return cleanDisplayText(job.minEdubg);
        return getCodeLabels(job, 'edubg', 'prvEdu', job.minEdubg || job.jobAcdmcrCd);
    }

    function getDisplayJobName(job) {
        var text = cleanDisplayText(job.jobsNm);
        if (hasReadableText(text)) return stripTrailingCode(text);
        return getCodeLabels(job, 'ncs', 'prvJob', job.jobsCd || job.jobsNm);
    }

    function getCodeLabels(job, publicGroup, privateGroup, value) {
        var group = isPublicJob(job) ? publicGroup : privateGroup;
        var labels = String(value || '').split(',').map(function (code) {
            code = code.trim();
            if (!code) return '';
            return getCommonCodeLabel(group, normalizeDisplayCode(group, code));
        }).filter(function (label) {
            return label && !/^[0-9]+$/.test(label);
        });
        return labels.join(', ');
    }

    function normalizeDisplayCode(group, code) {
        var numeric = String(code || '').trim();
        if (!/^[0-9]+$/.test(numeric)) return code;
        var n = parseInt(numeric, 10);
        if (group === 'career') return ['R2010', 'R2020', 'R2030', 'R2040'][n - 1] || code;
        if (group === 'edubg') return ['R7010', 'R7020', 'R7030', 'R7040', 'R7050', 'R7060', 'R7070'][n - 1] || code;
        if (group === 'empTp') return ['R1010', 'R1020', 'R1030', 'R1040', 'R1050', 'R1060', 'R1070'][n - 1] || code;
        if (group === 'ncs') return 'R600' + String(n).padStart(3, '0');
        return code;
    }

    function hasReadableText(value) {
        return !!value && !/^[0-9,\s]+$/.test(String(value));
    }

    function cleanDisplayText(value) {
        return String(value || '').replace(/\s+/g, ' ').trim();
    }

    function stripTrailingCode(value) {
        return cleanDisplayText(value).replace(/\s*\([0-9,]+\)\s*$/, '');
    }

    function shortenDisplayText(value, maxLength) {
        value = cleanDisplayText(value);
        return value.length > maxLength ? value.slice(0, maxLength - 1) + '...' : value;
    }

    function renderJobResults(data, bounds, markerData) {
        var markerJobs = markerData || data;
        state.currentMarkerJobs = markerJobs;
        if (state.mapReady) renderMarkers(markerJobs);
        else if (state.mapFailed) renderLocalMarkers(markerJobs, bounds);
        state.currentJobs = data;
        renderJobList(data);
        if (state.mapReady) updateLocationLabel();
    }

    function loadMoreJobs() {
        if (state.loading || state.loadingMoreJobs || !state.hasMoreJobs) return;

        state.loadingMoreJobs = true;
        showListUpdating(true);

        var bounds = getSearchBounds();
        var nextPage = state.currentJobPage + 1;
        var params = buildJobSearchParams(bounds, nextPage);

        fetch(apiUrl('/api/v1/map/jobs?' + params))
            .then(parseJobListResponse)
            .then(function (result) {
                var data = prepareJobsForDisplay(result.data);
                state.currentJobPage = nextPage;
                state.totalJobCount = getTotalJobCount(result.totalCount, state.currentJobs.length + data.length);
                state.currentJobs = state.currentJobs.concat(data);
                state.hasMoreJobs = state.currentJobs.length < state.totalJobCount;
                state.currentMarkerJobs = mergeUniqueJobs((state.currentMarkerJobs || []).concat(state.currentJobs));
                if (state.mapReady) renderMarkers(state.currentMarkerJobs);
                else if (state.mapFailed) renderLocalMarkers(state.currentMarkerJobs, bounds);
                renderJobList(state.currentJobs);
            })
            .catch(function () {
                showToast('추가 채용공고를 불러오지 못했습니다.');
            })
            .finally(function () {
                state.loadingMoreJobs = false;
                showListUpdating(false);
            });
    }

    function parseJobListResponse(r) {
        if (!r.ok) throw new Error(r.status);
        var totalCount = parseInt(r.headers.get('X-Total-Count'), 10);
        if (Number.isNaN(totalCount)) totalCount = null;
        return r.json().then(function (data) {
            return { data: data || [], totalCount: totalCount };
        });
    }

    function getTotalJobCount(totalCount, fallbackCount) {
        return typeof totalCount === 'number' ? totalCount : fallbackCount;
    }

    function geocodeMissingJobs(baseParams) {
        if (!state.mapReady || !window.kakao || !kakao.maps || !kakao.maps.services) return;
        if (state.geocodeInFlight) return;

        var params = new URLSearchParams(baseParams.toString());
        params.set('page', '1');
        params.set('size', String(GEOCODE_BATCH_SIZE));

        state.geocodeInFlight = true;
        fetch(apiUrl('/api/v1/map/jobs/coord-pending?' + params))
            .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
            .then(function (jobs) {
                jobs = (jobs || []).filter(function (job) {
                    return job && job.wantedAuthNo && !state.geocodeSkippedIds[job.wantedAuthNo] && !state.geocodeSavedIds[job.wantedAuthNo] && getJobAddress(job);
                });
                return geocodeJobsSequentially(jobs);
            })
            .then(function (savedCount) {
                if (savedCount > 0) {
                    setTimeout(loadJobs, 250);
                }
            })
            .catch(function () {
                // 지도 표출 자체는 기존 캐시 좌표로 계속 동작해야 하므로 조용히 실패 처리한다.
            })
            .finally(function () {
                state.geocodeInFlight = false;
            });
    }

    function geocodeJobsSequentially(jobs) {
        var savedCount = 0;
        return (jobs || []).reduce(function (chain, job) {
            return chain.then(function () {
                return geocodeAndSaveJob(job).then(function (saved) {
                    if (saved) savedCount += 1;
                });
            });
        }, Promise.resolve()).then(function () {
            return savedCount;
        });
    }

    function geocodeAndSaveJob(job) {
        var address = getJobAddress(job);
        if (!address) return Promise.resolve(false);

        return geocodeAddress(address).then(function (coord) {
            if (!coord) {
                state.geocodeSkippedIds[job.wantedAuthNo] = true;
                return false;
            }
            return saveJobCoord({
                wantedAuthNo: job.wantedAuthNo,
                lat: coord.lat,
                lng: coord.lng,
                geocodeYn: 'Y'
            }).then(function () {
                state.geocodeSavedIds[job.wantedAuthNo] = true;
                return true;
            }).catch(function () {
                return false;
            });
        }).catch(function () {
            state.geocodeSkippedIds[job.wantedAuthNo] = true;
            return false;
        });
    }

    function getJobAddress(job) {
        return [job && job.basicAddr, job && job.detailAddr].filter(Boolean).join(' ').trim();
    }

    function geocodeAddress(address) {
        return new Promise(function (resolve) {
            var geocoder = new kakao.maps.services.Geocoder();
            geocoder.addressSearch(address, function (result, status) {
                if (status !== kakao.maps.services.Status.OK || !result || !result.length) {
                    resolve(null);
                    return;
                }
                resolve({ lat: result[0].y, lng: result[0].x });
            });
        });
    }

    function saveJobCoord(coord) {
        return fetch(apiUrl('/api/v1/map/jobs/coords'), {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify(coord)
        }).then(function (r) {
            if (!r.ok) throw new Error(r.status);
            return true;
        });
    }

    /* ─── 마커 ─── */
    function getSelectedMarkerCharacterHtml() {
        return '<span class="selected-marker-character" aria-hidden="true">' +
            '<img class="selected-marker-character-base" src="/map/images/brand/jobaba-marker-character-base.svg" alt="">' +
            '<img class="selected-marker-character-magnifier" src="/map/images/brand/jobaba-marker-character-magnifier.svg" alt="">' +
        '</span>';
    }

    function renderMarkers(jobs) {
        if (!state.mapReady || !state.map) return;
        hideMarkerJobPopover();
        state.markers.forEach(function (m) { m.overlay.setMap(null); });
        state.markers = [];
        state.selectedMarker = null;

        buildMarkerGroups(jobs).forEach(function (group, index) {
            var pos = new kakao.maps.LatLng(group.lat, group.lng);
            var kind = getGroupKind(group);
            var sizeClass = getMarkerSizeClass(group.jobs.length);
            var markerId = 'group-' + index;
            var content =
                '<button type="button" class="job-marker ' + kind.className + ' ' + sizeClass + '" data-id="' + markerId + '" aria-label="' + escapeHtml(kind.label + ' 채용공고 ' + group.jobs.length + '건') + '">' +
                    getSelectedMarkerCharacterHtml() +
                    '<span class="job-marker-icon">' + group.jobs.length + '</span>' +
                '</button>';
            var overlay = new kakao.maps.CustomOverlay({ position: pos, content: content, yAnchor: .5 });
            overlay.setMap(state.map);
            var mo = { job: group.jobs[0], jobs: group.jobs, overlay: overlay, markerId: markerId };
            state.markers.push(mo);
            setTimeout(function () {
                var el = document.querySelector('.job-marker[data-id="' + markerId + '"]');
                if (el) {
                    mo.el = el;
                    el.addEventListener('click', function (e) {
                        e.preventDefault();
                        e.stopPropagation();
                        selectMarker(mo);
                    }, true);
                }
            }, 60);
        });
    }

    function buildMarkerGroups(jobs) {
        var level = state.mapReady && state.map ? state.map.getLevel() : DEFAULT_LEVEL;
        var cellSize = level <= 5 ? 0.006 : level <= 7 ? 0.014 : level <= 9 ? 0.035 : 0.07;
        var groups = {};

        (jobs || []).forEach(function (job) {
            var lat = parseFloat(job.lat);
            var lng = parseFloat(job.lng);
            if (Number.isNaN(lat) || Number.isNaN(lng)) return;

            var key = Math.round(lat / cellSize) + ':' + Math.round(lng / cellSize);
            if (!groups[key]) {
                groups[key] = { latSum: 0, lngSum: 0, publicCount: 0, privateCount: 0, jobs: [] };
            }
            groups[key].latSum += lat;
            groups[key].lngSum += lng;
            groups[key].jobs.push(job);
            if (isPublicJob(job)) groups[key].publicCount += 1;
            else groups[key].privateCount += 1;
        });

        return Object.keys(groups).map(function (key) {
            var group = groups[key];
            group.lat = group.latSum / group.jobs.length;
            group.lng = group.lngSum / group.jobs.length;
            return group;
        }).sort(function (a, b) {
            return b.jobs.length - a.jobs.length;
        });
    }

    function getGroupKind(group) {
        if (group.publicCount && group.privateCount) {
            return { className: 'is-mixed', label: '공공+민간' };
        }
        if (group.publicCount) {
            return { className: 'is-public', label: '공공기관' };
        }
        return { className: 'is-private', label: '민간기업' };
    }

    function getMarkerSizeClass(count) {
        if (count >= 50) return 'size-xl';
        if (count >= 20) return 'size-lg';
        if (count >= 5) return 'size-md';
        return 'size-sm';
    }

    function renderLocalMarkers(jobs, bounds) {
        var markerLayer = $('localMarkers');
        if (!markerLayer) return;
        hideMarkerJobPopover();
        markerLayer.innerHTML = '';
        state.markers = [];
        state.selectedMarker = null;

        buildMarkerGroups(jobs).forEach(function (group) {
            var job = group.jobs[0];
            if (!job.lat || !job.lng) return;
            var lat = group.lat;
            var lng = group.lng;
            if (Number.isNaN(lat) || Number.isNaN(lng)) return;

            var x = ((lng - bounds.swLng) / (bounds.neLng - bounds.swLng)) * 100;
            var y = ((bounds.neLat - lat) / (bounds.neLat - bounds.swLat)) * 100;
            if (x < -5 || x > 105 || y < -5 || y > 105) return;

            var marker = document.createElement('button');
            marker.type = 'button';
            marker.className = 'local-job-marker ' + getGroupKind(group).className;
            marker.dataset.id = job.wantedAuthNo;
            marker.style.left = Math.max(2, Math.min(98, x)) + '%';
            marker.style.top = Math.max(2, Math.min(98, y)) + '%';
            marker.innerHTML =
                getSelectedMarkerCharacterHtml() +
                '<span class="local-marker-dot"></span>' +
                '<span class="local-marker-label">' + group.jobs.length + '건</span>';

            var mo = { job: job, jobs: group.jobs, el: marker };
            marker.addEventListener('click', function () { selectMarker(mo); });
            markerLayer.appendChild(marker);
            state.markers.push(mo);
        });
    }

    function selectMarker(mo, selectedJob) {
        var jobs = mo.jobs || (mo.job ? [mo.job] : []);
        var job = selectedJob || mo.job || jobs[0];
        if (!job) return;
        if (!mo.el && mo.markerId) {
            mo.el = document.querySelector('.job-marker[data-id="' + mo.markerId + '"]');
        }
        if (state.selectedMarker && state.selectedMarker.el)
            state.selectedMarker.el.classList.remove('selected');
        if (state.selectedMarker && state.selectedMarker.overlay)
            state.selectedMarker.overlay.setZIndex(0);
        state.selectedMarker = mo;
        if (mo.el) mo.el.classList.add('selected');
        if (mo.overlay) mo.overlay.setZIndex(210);
        if (!selectedJob && jobs.length > 1) {
            showMarkerJobPopover(mo);
            return;
        }
        hideMarkerJobPopover();
        if (state.mapReady && state.map) {
            state.suppressIdleLoadUntil = Date.now() + 1500;
            state.map.panTo(new kakao.maps.LatLng(parseFloat(job.lat), parseFloat(job.lng)));
        }
        loadJobDetail(job.wantedAuthNo);
        document.querySelectorAll('.job-item').forEach(function (el) {
            el.classList.toggle('active', el.dataset.id === job.wantedAuthNo);
        });
    }

    function showMarkerJobPopover(mo) {
        var jobs = mo.jobs || [];
        if (!jobs.length || !mo.el) return;
        hideMarkerJobPopover();

        var mapContainer = $('mapContainer');
        var popover = document.createElement('div');
        popover.className = 'marker-job-popover';
        popover.setAttribute('role', 'dialog');
        popover.setAttribute('aria-label', '마커 채용공고 목록');
        popover.innerHTML =
            '<div class="marker-popover-head">' +
                '<strong>공고 ' + jobs.length + '건</strong>' +
                '<button type="button" class="marker-popover-close" aria-label="공고 목록 닫기">×</button>' +
            '</div>' +
            '<div class="marker-popover-list">' +
                jobs.map(function (job, index) {
                    var title = job.title || job.company || '채용공고';
                    var isPrivate = !isPublicJob(job);
                    var kindLabel = isPrivate ? '민간' : '공공';
                    var company = job.company || job.instNm || '';
                    return '<button type="button" class="marker-popover-item" data-index="' + index + '">' +
                        '<span class="marker-popover-kind ' + (isPrivate ? 'is-private' : 'is-public') + '">' + kindLabel + '</span>' +
                        '<span class="marker-popover-text">' +
                            '<span class="marker-popover-title">' + escapeHtml(title) + '</span>' +
                            (company ? '<span class="marker-popover-company">' + escapeHtml(company) + '</span>' : '') +
                        '</span>' +
                    '</button>';
                }).join('') +
            '</div>';

        mapContainer.appendChild(popover);
        state.markerPopoverEl = popover;

        popover.querySelector('.marker-popover-close').addEventListener('click', function (e) {
            e.stopPropagation();
            hideMarkerJobPopover();
        });
        popover.querySelectorAll('.marker-popover-item').forEach(function (btn) {
            btn.addEventListener('click', function (e) {
                e.stopPropagation();
                var selected = jobs[parseInt(btn.dataset.index, 10)];
                if (selected) selectMarker(mo, selected);
            });
        });

        positionMarkerJobPopover(mo, popover);
    }

    function positionMarkerJobPopover(mo, popover) {
        var mapContainer = $('mapContainer');
        var mapRect = mapContainer.getBoundingClientRect();
        var markerRect = mo.el.getBoundingClientRect();
        var left = markerRect.left + markerRect.width / 2 - mapRect.left;
        var markerTop = markerRect.top - mapRect.top;
        var markerBottom = markerRect.bottom - mapRect.top;
        var width = popover.offsetWidth || 280;
        left = Math.max(14 + width / 2, Math.min(mapRect.width - width / 2 - 14, left));

        var edgeGap = 14;
        var markerGap = 12;
        var aboveSpace = markerTop - markerGap - edgeGap;
        var belowSpace = mapRect.height - markerBottom - markerGap - edgeGap;
        var placeBelow = belowSpace >= aboveSpace;
        var availableSpace = placeBelow ? belowSpace : aboveSpace;
        if (availableSpace < 140) {
            placeBelow = !placeBelow;
            availableSpace = placeBelow ? belowSpace : aboveSpace;
        }

        var maxHeight = Math.max(120, Math.min(300, availableSpace));
        var list = popover.querySelector('.marker-popover-list');
        popover.style.maxHeight = maxHeight + 'px';
        if (list) {
            list.style.maxHeight = Math.max(70, maxHeight - 43) + 'px';
        }
        popover.style.left = left + 'px';
        popover.classList.toggle('is-below', placeBelow);
        if (placeBelow) {
            popover.style.top = markerBottom + 'px';
        } else {
            popover.style.top = markerTop + 'px';
        }

        if (!placeBelow && markerTop - popover.offsetHeight - markerGap < edgeGap) {
            popover.classList.add('is-below');
            popover.style.top = markerBottom + 'px';
        }
    }

    function hideMarkerJobPopover() {
        if (state.markerPopoverEl) {
            state.markerPopoverEl.remove();
            state.markerPopoverEl = null;
        }
    }

    function setMobileView(view) {
        if (!$mainLayout) return;
        var isList = view === 'list';
        if (isList && state.mapReady && state.map && window.kakao) {
            var center = state.map.getCenter();
            state.mobileListMapViewport = {
                lat: center.getLat(),
                lng: center.getLng(),
                level: state.map.getLevel()
            };
        }
        $mainLayout.classList.toggle('mobile-list-view', isList);
        $mainLayout.classList.toggle('mobile-map-view', !isList);
        if ($mobileMapViewBtn) {
            $mobileMapViewBtn.classList.toggle('is-active', !isList);
            $mobileMapViewBtn.setAttribute('aria-selected', !isList ? 'true' : 'false');
        }
        if ($mobileListViewBtn) {
            $mobileListViewBtn.classList.toggle('is-active', isList);
            $mobileListViewBtn.setAttribute('aria-selected', isList ? 'true' : 'false');
        }
        if (!isList && state.mapReady && state.map && window.kakao) {
            setTimeout(function () {
                if (typeof state.map.relayout === 'function') {
                    state.map.relayout();
                } else {
                    kakao.maps.event.trigger(state.map, 'resize');
                }
                if (state.mobileListMapViewport) {
                    state.map.setLevel(state.mobileListMapViewport.level);
                    state.map.setCenter(new kakao.maps.LatLng(
                        state.mobileListMapViewport.lat,
                        state.mobileListMapViewport.lng
                    ));
                }
            }, 0);
        }
    }

    /* ─── 목록 ─── */
    function renderJobList(jobs) {
        jobs = jobs || [];
        setCount(state.totalJobCount);
        $jobList.innerHTML = '';
        $noResult.classList.toggle('hidden', jobs.length > 0);
        $jobList.classList.toggle('hidden', jobs.length === 0);
        if (!jobs.length) return;

        jobs.forEach(function (job) {
            var li = document.createElement('li');
            li.className = 'job-item';
            li.dataset.id = job.wantedAuthNo;
            var publicJob = isPublicJob(job);
            var badgeCls = publicJob ? 'badge-public' : 'badge-private';
            var badgeText = publicJob ? '공공' : '민간';
            var dday = formatDday(job.closeDt);
            var meta = getDisplayJobMeta(job);
            var tags = [
                meta.empTpNm,
                meta.career,
                meta.minEdubg,
                meta.jobsNm
            ].filter(Boolean).slice(0, 4);

            li.innerHTML =
                '<div class="job-company">' +
                    '<span class="' + badgeCls + '">' + badgeText + '</span>' +
                    '<span class="job-company-name">' + escapeHtml(job.company || '') + '</span>' +
                '</div>' +
                (dday ? '<span class="job-dday">' + escapeHtml(dday) + '</span>' : '') +
                '<div class="job-title">' + escapeHtml(job.title || '') + '</div>' +
                '<div class="job-meta">' +
                    tags.map(function (tag) { return '<span class="job-tag">' + escapeHtml(tag) + '</span>'; }).join('') +
                '</div>' +
                '<div class="job-card-footer">' +
                    '<span class="job-deadline">' + (job.closeDt ? '마감 ' + escapeHtml(formatDateOnly(job.closeDt)) : '마감일 미정') + '</span>' +
                '</div>';
            li.addEventListener('click', function () {
                var found = state.markers.find(function (m) {
                    return (m.jobs || [m.job]).some(function (markerJob) {
                        return markerJob.wantedAuthNo === job.wantedAuthNo;
                    });
                });
                if (found) { selectMarker(found, job); return; }
                loadJobDetail(job.wantedAuthNo);
            });
            $jobList.appendChild(li);
        });
    }

    function setCount(n) {
        $jobCount.innerHTML = '검색결과 <strong>' + n.toLocaleString() + '개</strong>';
    }

    function handleJobListScroll() {
        var remaining = $jobList.scrollHeight - $jobList.scrollTop - $jobList.clientHeight;
        if (remaining <= LIST_SCROLL_THRESHOLD) loadMoreJobs();
    }

    /* ─── 상세 ─── */
    function loadJobDetail(id) {
        showLoading(true);
        fetch(apiUrl('/api/v1/map/jobs/' + encodeURIComponent(id)))
            .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
            .then(function (job) { renderJobDetail(job); $jobDetail.classList.remove('hidden'); })
            .catch(function () { showToast('상세 정보를 불러오지 못했습니다.'); })
            .finally(function () { showLoading(false); });
    }

    function renderJobDetail(job) {
        var addr = [job.basicAddr, job.detailAddr].filter(Boolean).join(' ');
        var publicJob = isPublicJob(job);
        var kindText = publicJob ? '공공기관' : '민간기업';
        var meta = getDisplayJobMeta(job);
        var salary = formatSal(job.salTpNm, job.salAmt);
        var subtitle = meta.jobsNm || addr;
        var safeWantedInfoUrl = getSafeExternalUrl(job.wantedInfoUrl);
        $detailContent.innerHTML =
            '<span class="detail-kind ' + (publicJob ? 'is-public' : 'is-private') + '">' + kindText + '</span>' +
            '<p class="detail-company">' + escapeHtml(job.company || '') + '</p>' +
            '<h3 class="detail-title">' + escapeHtml(job.title || '') + '</h3>' +
            (subtitle ? '<p class="detail-subtitle">' + escapeHtml(subtitle) + '</p>' : '') +
            '<div class="detail-divider"></div>' +
            '<div class="detail-info">' +
                infoItem('고용형태', meta.empTpNm) + infoItem('경력', meta.career) +
                infoItem('학력', meta.minEdubg) + infoItem('직종', meta.jobsNm) +
            '</div>' +
            (salary ? '<div class="detail-salary"><span class="detail-info-label">급여</span><span class="detail-salary-value">' + escapeHtml(salary) + '</span></div>' : '') +
            (job.closeDt ? '<div class="detail-deadline"><span class="detail-info-label">마감일</span><span>' + escapeHtml(formatCloseDt(job.closeDt)) + '</span></div>' : '') +
            (addr ? '<p class="detail-addr">' +
                '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>' +
                escapeHtml(addr) + '</p>' : '') +
            (safeWantedInfoUrl ? '<a href="' + escapeHtml(safeWantedInfoUrl) + '" target="_blank" rel="noopener" class="btn-go-detail">채용공고 바로가기 <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M7 17L17 7"/><path d="M7 7h10v10"/></svg></a>' : '');
    }

    function infoItem(l, v) {
        return v ? '<div class="detail-info-item"><span class="detail-info-label">' + l + '</span><span class="detail-info-value">' + escapeHtml(v) + '</span></div>' : '';
    }

    /* ─── 검색 ─── */
    if ($searchBtn && $searchInput) {
        $searchBtn.addEventListener('click', doSearch);
        $searchInput.addEventListener('keydown', function (e) { if (e.key === 'Enter') doSearch(); });
        $searchInput.addEventListener('input', function () {
            if ($panelSearchInput && $panelSearchInput.value !== this.value) $panelSearchInput.value = this.value;
        });
        $searchInput.addEventListener('focus', renderRecentSearches);
        $searchInput.addEventListener('blur', function () {
            setTimeout(function () { $recentSearches.classList.add('hidden'); }, 200);
        });
    }
    function doSearch() {
        var input = $searchInput || $panelSearchInput;
        var kw = input ? input.value.trim() : '';
        runSearch(kw);
    }

    function runSearch(kw) {
        kw = (kw || '').trim();
        if (kw) saveRecentSearch(kw);
        state.keyword = kw;
        if ($searchInput) $searchInput.value = kw;
        if ($panelSearchInput) $panelSearchInput.value = kw;
        loadJobs();
    }

    if ($panelSearchBtn && $panelSearchInput) {
        $panelSearchBtn.addEventListener('click', function () { runSearch($panelSearchInput.value); });
        $panelSearchInput.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') runSearch($panelSearchInput.value);
        });
        $panelSearchInput.addEventListener('input', function () {
            if ($searchInput && $searchInput.value !== this.value) $searchInput.value = this.value;
        });
        $panelSearchInput.addEventListener('focus', renderRecentSearches);
        $panelSearchInput.addEventListener('blur', function () {
            setTimeout(function () { $recentSearches.classList.add('hidden'); }, 200);
        });
    }

    function updateSearchPlaceholder() {
        if (!$searchInput) return;
        $searchInput.placeholder = window.innerWidth <= 480
            ? '직종, 기업명, 키워드'
            : '검색어를 입력하세요 (직종, 기업명, 키워드)';
    }
    updateSearchPlaceholder();
    window.addEventListener('resize', updateSearchPlaceholder);

    /* ─── 최근 검색 ─── */
    function getRecent() { try { return JSON.parse(localStorage.getItem(RECENT_KEY)) || []; } catch (e) { return []; } }
    function saveRecentSearch(kw) {
        var list = getRecent().filter(function (s) { return s !== kw; });
        list.unshift(kw);
        if (list.length > MAX_RECENT) list.pop();
        try { localStorage.setItem(RECENT_KEY, JSON.stringify(list)); } catch (e) {}
    }
    function renderRecentSearches() {
        var list = getRecent();
        if (!list.length) { $recentSearches.classList.add('hidden'); return; }
        $recentList.innerHTML = '';
        list.forEach(function (kw) {
            var li = document.createElement('li');
            li.className = 'recent-item';
            li.innerHTML = '<span>' + escapeHtml(kw) + '</span><span class="recent-del">×</span>';
            li.querySelector('span').addEventListener('click', function () { runSearch(kw); });
            li.querySelector('.recent-del').addEventListener('click', function (e) {
                e.stopPropagation();
                var u = getRecent().filter(function (s) { return s !== kw; });
                try { localStorage.setItem(RECENT_KEY, JSON.stringify(u)); } catch (e2) {}
                renderRecentSearches();
            });
            $recentList.appendChild(li);
        });
        $recentSearches.classList.remove('hidden');
    }
    $clearRecentBtn.addEventListener('click', function () {
        try { localStorage.removeItem(RECENT_KEY); } catch (e) {}
        $recentSearches.classList.add('hidden');
    });

    /* ─── 정렬 ─── */
    function setSortType(value, label) {
        state.sortType = value;
        if ($sortTypeLabel) $sortTypeLabel.textContent = label;
        document.querySelectorAll('.sort-option').forEach(function (btn) {
            var active = btn.dataset.sort === value;
            btn.classList.toggle('is-active', active);
            btn.setAttribute('aria-current', active ? 'true' : 'false');
        });
    }

    document.querySelectorAll('.sort-option').forEach(function (btn) {
        btn.addEventListener('click', function () {
            setSortType(this.dataset.sort, this.textContent.trim());
            if ($sortTypeBtn) $sortTypeBtn.focus();
            loadJobs();
        });
    });

    /* ─── 필터 모달 ─── */
    function openFilter() {
        $filterModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }
    function closeFilter() { $filterModal.classList.add('hidden'); document.body.style.overflow = ''; }

    if ($filterBtn)  $filterBtn.addEventListener('click', openFilter);
    if ($filterBtn2) $filterBtn2.addEventListener('click', openFilter);
    [$panelJobBtn, $panelAdvancedBtn].forEach(function (btn) {
        if (btn) btn.addEventListener('click', openFilter);
    });
    [$panelCareerSelect, $panelEmpSelect, $panelEduSelect].forEach(function (select) {
        if (select) {
            select.addEventListener('change', applyPanelSelectFilters);
        }
    });
    $filterCloseBtn.addEventListener('click', closeFilter);
    $filterOverlay.addEventListener('click', closeFilter);

    // ─── 채널 탭 (상단 공공/민간) ───
    document.querySelectorAll('.src-tab').forEach(function (tab) {
        tab.addEventListener('click', function () {
            document.querySelectorAll('.src-tab').forEach(function (t) {
                t.classList.remove('src-tab-active');
                t.setAttribute('aria-selected', 'false');
            });
            this.classList.add('src-tab-active');
            this.setAttribute('aria-selected', 'true');
            state.sourceType = this.dataset.src;
            resetFilter();
            populatePanelSelects();
            syncModalFilterTabs();
            loadJobs();
        });
    });

    // ─── 필터 모달 내 채널 탭 ───
    document.querySelectorAll('.filter-src-tab').forEach(function (tab) {
        tab.addEventListener('click', function () {
            document.querySelectorAll('.filter-src-tab').forEach(function (t) {
                t.classList.remove('filter-src-tab-active');
                t.setAttribute('aria-selected', 'false');
            });
            this.classList.add('filter-src-tab-active');
            this.setAttribute('aria-selected', 'true');
            state.sourceType = this.dataset.src;
            // 상단 채널 탭도 동기화
            document.querySelectorAll('.src-tab').forEach(function (t) {
                var isActive = t.dataset.src === state.sourceType;
                t.classList.toggle('src-tab-active', isActive);
                t.setAttribute('aria-selected', isActive ? 'true' : 'false');
            });
            var $pub = $('filterSectionPub');
            var $prv = $('filterSectionPrv');
            if ($pub) $pub.classList.toggle('hidden', state.sourceType !== 'PUB');
            if ($prv) $prv.classList.toggle('hidden', state.sourceType !== 'PRV');
            populatePanelSelects();
            updateFilterSummaryPreview();
        });
    });

    function syncModalFilterTabs() {
        var modalSourceType = state.sourceType === 'PRV' ? 'PRV' : 'PUB';
        document.querySelectorAll('.filter-src-tab').forEach(function (tab) {
            var isActive = tab.dataset.src === modalSourceType;
            tab.classList.toggle('filter-src-tab-active', isActive);
            tab.setAttribute('aria-selected', isActive ? 'true' : 'false');
        });
        var $pub = $('filterSectionPub');
        var $prv = $('filterSectionPrv');
        if ($pub) $pub.classList.toggle('hidden', modalSourceType !== 'PUB');
        if ($prv) $prv.classList.toggle('hidden', modalSourceType !== 'PRV');
    }

    // 전체 체크박스 연동
    function bindAllCheckbox(allId, groupName) {
        var allCb = $(allId);
        if (!allCb) return;
        var others = document.querySelectorAll('input[name="' + groupName + '"]:not([value=""])');
        allCb.addEventListener('change', function () {
            if (this.checked) others.forEach(function (cb) { cb.checked = false; });
            else if (!Array.from(others).some(function (cb) { return cb.checked; })) this.checked = true;
        });
        others.forEach(function (cb) {
            cb.addEventListener('change', function () {
                if (this.checked) {
                    allCb.checked = false;
                }
                if (!Array.from(others).some(function (c) { return c.checked; })) allCb.checked = true;
            });
        });
    }
    bindAllCheckbox('pubNcsAll',    'pubNcs');
    bindAllCheckbox('pubEmpTpAll',  'pubEmpTp');
    bindAllCheckbox('pubCareerAll', 'pubCareer');
    bindAllCheckbox('pubEduAll',    'pubEdu');
    bindAllCheckbox('prvJobAll',    'prvJob');
    bindAllCheckbox('prvEmpTpAll',  'prvEmpTp');
    bindAllCheckbox('prvCareerAll', 'prvCareer');
    bindAllCheckbox('prvEduAll',    'prvEdu');

    document.querySelectorAll('#filterModal input[type="checkbox"]').forEach(function (checkbox) {
        checkbox.addEventListener('change', updateFilterSummaryPreview);
    });
    if ($salaryType) $salaryType.addEventListener('change', function () {
        syncSalaryControls();
        updateFilterSummaryPreview();
    });
    if ($salaryNoCondition) $salaryNoCondition.addEventListener('change', function () {
        syncSalaryControls();
        updateFilterSummaryPreview();
    });
    [$salaryMin, $salaryMax].forEach(function (input) {
        if (input) input.addEventListener('input', updateFilterSummaryPreview);
    });
    syncSalaryControls();

    $filterResetBtn.addEventListener('click', resetFilter);
    $filterApplyBtn.addEventListener('click', applyFilter);

    function resetFilter() {
        ['pubNcs','pubEmpTp','pubCareer','pubEdu',
         'prvJob','prvEmpTp','prvCareer','prvEdu'].forEach(function (name) {
            document.querySelectorAll('input[name="' + name + '"]').forEach(function (cb) { cb.checked = false; });
        });
        ['pubNcsAll','pubEmpTpAll','pubCareerAll','pubEduAll',
         'prvJobAll','prvEmpTpAll','prvCareerAll','prvEduAll'].forEach(function (id) {
            var el = $(id); if (el) el.checked = true;
        });
        state.pubNcsCds = []; state.pubEmpTpCds = []; state.pubCareerCds = []; state.pubEduCds = [];
        state.prvJobCds = []; state.prvEmpTpCds = []; state.prvCareerCds = []; state.prvEduCds = [];
        state.salaryType = ''; state.salaryMin = ''; state.salaryMax = ''; state.salaryNoCondition = true;
        resetSalaryControls();
        state.filterCount = 0;
        updateFilterButtons(0);
        syncPanelSelects();
        $filterSummary.textContent = '검색조건을 선택해 주세요.';
    }

    function applyFilter() {
        var activeFilterTab = document.querySelector('.filter-src-tab-active');
        var salaryNoCondition = !$salaryNoCondition || $salaryNoCondition.checked;
        var salaryType = $salaryType ? $salaryType.value : '';
        var salaryMin = $salaryMin ? $salaryMin.value.trim() : '';
        var salaryMax = $salaryMax ? $salaryMax.value.trim() : '';
        if (!salaryNoCondition && !isValidSalaryAmount(salaryMin)) {
            showToast('희망임금 최소 금액은 0 이상의 정수로 입력해 주세요.');
            $salaryMin.focus();
            return;
        }
        if (!salaryNoCondition && !isValidSalaryAmount(salaryMax)) {
            showToast('희망임금 최대 금액은 0 이상의 정수로 입력해 주세요.');
            $salaryMax.focus();
            return;
        }
        if (!salaryNoCondition && salaryMin !== '' && salaryMax !== '' && Number(salaryMin) > Number(salaryMax)) {
            showToast('희망임금 최소 금액은 최대 금액보다 클 수 없습니다.');
            $salaryMin.focus();
            return;
        }
        state.pubNcsCds    = getCheckedValues('pubNcs');
        state.pubEmpTpCds  = getCheckedValues('pubEmpTp');
        state.pubCareerCds = getCheckedValues('pubCareer');
        state.pubEduCds    = getCheckedValues('pubEdu');
        state.prvJobCds    = getCheckedValues('prvJob');
        state.prvEmpTpCds  = getCheckedValues('prvEmpTp');
        state.prvCareerCds = getCheckedValues('prvCareer');
        state.prvEduCds    = getCheckedValues('prvEdu');
        state.salaryNoCondition = salaryNoCondition;
        state.salaryType = salaryNoCondition ? '' : salaryType;
        state.salaryMin = salaryNoCondition ? '' : salaryMin;
        state.salaryMax = salaryNoCondition ? '' : salaryMax;

        var activePubFilters = state.pubNcsCds.length + state.pubEmpTpCds.length +
                               state.pubCareerCds.length + state.pubEduCds.length;
        var activePrvFilters = state.prvJobCds.length + state.prvEmpTpCds.length +
                               state.prvCareerCds.length + state.prvEduCds.length + getSalaryFilterCount();
        if (activeFilterTab && activeFilterTab.dataset.src) {
            var shouldSyncSource = activeFilterTab.dataset.src === 'PUB' ? activePubFilters > 0 : activePrvFilters > 0;
            if (shouldSyncSource) {
                state.sourceType = activeFilterTab.dataset.src;
                document.querySelectorAll('.src-tab').forEach(function (t) {
                    var isActive = t.dataset.src === state.sourceType;
                    t.classList.toggle('src-tab-active', isActive);
                    t.setAttribute('aria-selected', isActive ? 'true' : 'false');
                });
            }
        }

        var totalActive = state.pubNcsCds.length + state.pubEmpTpCds.length +
                          state.pubCareerCds.length + state.pubEduCds.length +
                          state.prvJobCds.length + state.prvEmpTpCds.length +
                          state.prvCareerCds.length + state.prvEduCds.length + getSalaryFilterCount();
        state.filterCount = totalActive;
        updateFilterButtons(totalActive);
        syncPanelSelects();
        updateFilterSummary();
        closeFilter();
        loadJobs();
    }

    function applyPanelSelectFilters() {
        var careerVal = $panelCareerSelect && $panelCareerSelect.value ? [$panelCareerSelect.value] : [];
        var empVal    = $panelEmpSelect    && $panelEmpSelect.value    ? [$panelEmpSelect.value]    : [];
        var eduVal    = $panelEduSelect    && $panelEduSelect.value    ? [$panelEduSelect.value]    : [];
        if (state.sourceType === 'PRV') {
            state.prvCareerCds = careerVal;
            state.prvEmpTpCds  = empVal;
            state.prvEduCds    = eduVal;
        } else {
            state.pubCareerCds = careerVal;
            state.pubEmpTpCds  = empVal;
            state.pubEduCds    = eduVal;
        }
        var totalActive = state.pubNcsCds.length + state.pubEmpTpCds.length +
                          state.pubCareerCds.length + state.pubEduCds.length +
                          state.prvJobCds.length + state.prvEmpTpCds.length +
                          state.prvCareerCds.length + state.prvEduCds.length + getSalaryFilterCount();
        state.filterCount = totalActive;
        updatePanelSelectStates();
        updateFilterButtons(totalActive);
        updateFilterSummary();
        loadJobs();
    }

    function updateFilterButtons(cnt) {
        if ($filterBadge) {
            $filterBadge.textContent = cnt;
            $filterBadge.classList.toggle('hidden', cnt === 0);
        }
        if ($filterBtn) $filterBtn.classList.toggle('active', cnt > 0);
        if ($filterBtn2) $filterBtn2.classList.toggle('active', cnt > 0);
    }

    function populatePanelSelects() {
        var careerOpts, empOpts, eduOpts;
        if (state.sourceType === 'PRV') {
            careerOpts = [{v:'1',t:'신입'},{v:'2',t:'경력'},{v:'3',t:'신입/경력'},{v:'4',t:'관계없음'}];
            empOpts    = [{v:'1',t:'정규직'},{v:'2',t:'계약직'},{v:'3',t:'인턴직'},{v:'6',t:'프리랜서'},{v:'7',t:'아르바이트'}];
            eduOpts    = [{v:'0',t:'학력무관'},{v:'3',t:'고졸'},{v:'4',t:'대졸(2~3년)'},{v:'5',t:'대졸(4년)'},{v:'7',t:'박사'}];
        } else {
            careerOpts = [{v:'R2010',t:'신입'},{v:'R2020',t:'경력'},{v:'R2030',t:'신입+경력'},{v:'R2040',t:'외국인전형'}];
            empOpts    = [{v:'R1010',t:'정규직'},{v:'R1020',t:'계약직'},{v:'R1030',t:'무기계약직'},
                          {v:'R1040',t:'비정규직'},{v:'R1050',t:'청년인턴'},{v:'R1060',t:'청년인턴(체험형)'},{v:'R1070',t:'청년인턴(채용형)'}];
            eduOpts    = [{v:'R7010',t:'학력무관'},{v:'R7020',t:'중졸이하'},{v:'R7030',t:'고졸'},
                          {v:'R7040',t:'대졸(2~3년)'},{v:'R7050',t:'대졸(4년)'},{v:'R7060',t:'석사'},{v:'R7070',t:'박사'}];
        }
        [[$panelCareerSelect, careerOpts], [$panelEmpSelect, empOpts], [$panelEduSelect, eduOpts]].forEach(function (pair) {
            var sel = pair[0], opts = pair[1];
            if (!sel) return;
            var prev = sel.value;
            sel.innerHTML = '<option value="">전체</option>';
            opts.forEach(function (o) {
                var opt = document.createElement('option');
                opt.value = o.v; opt.textContent = o.t;
                sel.appendChild(opt);
            });
            sel.value = prev;
        });
    }

    function syncPanelSelects() {
        populatePanelSelects();
        if (state.sourceType === 'PRV') {
            if ($panelCareerSelect) $panelCareerSelect.value = state.prvCareerCds[0] || '';
            if ($panelEmpSelect)    $panelEmpSelect.value    = state.prvEmpTpCds[0]  || '';
            if ($panelEduSelect)    $panelEduSelect.value    = state.prvEduCds[0]    || '';
        } else {
            if ($panelCareerSelect) $panelCareerSelect.value = state.pubCareerCds[0] || '';
            if ($panelEmpSelect)    $panelEmpSelect.value    = state.pubEmpTpCds[0]  || '';
            if ($panelEduSelect)    $panelEduSelect.value    = state.pubEduCds[0]    || '';
        }
        updatePanelSelectStates();
    }

    function updatePanelSelectStates() {
        [$panelCareerSelect, $panelEmpSelect, $panelEduSelect].forEach(function (select) {
            if (select) select.classList.toggle('is-active', !!select.value);
        });
    }

    function getCheckedValues(name) {
        return Array.from(document.querySelectorAll('input[name="' + name + '"]:checked'))
            .map(function (cb) { return cb.value; })
            .filter(Boolean);
    }

    function syncSalaryControls() {
        var type = $salaryType ? $salaryType.value : '연봉';
        var unit = getSalaryUnit(type);
        var noCondition = !$salaryNoCondition || $salaryNoCondition.checked;
        if ($salaryMinUnit) $salaryMinUnit.textContent = unit;
        if ($salaryMaxUnit) $salaryMaxUnit.textContent = unit;
        if ($salaryMin) {
            $salaryMin.disabled = noCondition;
            $salaryMin.setAttribute('aria-label', '희망임금 최소 (' + unit + ')');
        }
        if ($salaryMax) {
            $salaryMax.disabled = noCondition;
            $salaryMax.setAttribute('aria-label', '희망임금 최대 (' + unit + ')');
        }
        if ($salaryType) $salaryType.disabled = noCondition;
        if ($salaryFilter) $salaryFilter.classList.toggle('is-disabled', noCondition);
    }

    function resetSalaryControls() {
        if ($salaryType) $salaryType.value = '연봉';
        if ($salaryMin) $salaryMin.value = '';
        if ($salaryMax) $salaryMax.value = '';
        if ($salaryNoCondition) $salaryNoCondition.checked = true;
        syncSalaryControls();
    }

    function getSalaryUnit(type) {
        return type === '연봉' || type === '월급' ? '만원' : '원';
    }

    function isValidSalaryAmount(value) {
        if (value === '') return true;
        var amount = Number(value);
        return /^\d+$/.test(value) && Number.isSafeInteger(amount);
    }

    function getSalaryFilterCount() {
        return state.salaryNoCondition ? 0 : 1;
    }

    function formatSalaryFilterSummary(filterState) {
        filterState = filterState || state;
        var type = filterState.salaryType || '연봉';
        var unit = getSalaryUnit(type);
        var min = filterState.salaryMin ? Number(filterState.salaryMin).toLocaleString('ko-KR') : '';
        var max = filterState.salaryMax ? Number(filterState.salaryMax).toLocaleString('ko-KR') : '';
        if (min && max) return '희망임금: ' + type + ' ' + min + '~' + max + unit;
        if (min) return '희망임금: ' + type + ' ' + min + unit + ' 이상';
        if (max) return '희망임금: ' + type + ' ' + max + unit + ' 이하';
        return '희망임금: ' + type;
    }

    function getFirstCommonCode(values) {
        return (values || []).find(function (value) {
            return /^R\d+/.test(value);
        }) || '';
    }

    function applyClientFilters(jobs) {
        return (jobs || []).filter(matchesOpenJob);
    }

    function matchesOpenJob(job) {
        return !isExpiredCloseDt(job && job.closeDt);
    }

    function matchesNcs(job) {
        if (!state.pubNcsCds.length) return true;
        return state.pubNcsCds.some(function (code) {
            return jobaba276MatchesNcs(code, job.jobabaCmmn276Cd);
        });
    }

    function matchesPrvJob(job) {
        if (!state.prvJobCds.length) return true;
        var text = normalizeText(job.jobsNm);
        return state.prvJobCds.some(function (code) {
            return codeContains(job.jobabaCmmn274Cd, code) ||
                   text.indexOf(normalizeText(getCommonCodeLabel('prvJob', code))) !== -1;
        });
    }

    function matchesCareer(job) {
        var codes = state.sourceType === 'PRV' ? state.prvCareerCds : state.pubCareerCds;
        if (!codes.length) return true;
        if (state.sourceType === 'PRV') {
            return codes.some(function (code) { return codeContains(job.jobCareerCd, code); });
        }
        var careerText = normalizeText(job.career);
        return codes.some(function (code) {
            return codeContains(job.jobCareerCd, code) ||
                   careerText.indexOf(normalizeText(getCommonCodeLabel('career', code))) !== -1;
        });
    }

    function matchesEducation(job) {
        var codes = state.sourceType === 'PRV' ? state.prvEduCds : state.pubEduCds;
        if (!codes.length) return true;
        if (state.sourceType === 'PRV') {
            return codes.some(function (code) { return String(job.jobAcdmcrCd) === String(code); });
        }
        var educationText = normalizeText(job.minEdubg);
        return codes.some(function (code) {
            return codeContains(job.jobAcdmcrCd, code) ||
                   educationText.indexOf(normalizeText(getCommonCodeLabel('edubg', code))) !== -1;
        });
    }

    function matchesEmploymentType(job) {
        var codes = state.sourceType === 'PRV' ? state.prvEmpTpCds : state.pubEmpTpCds;
        if (!codes.length) return true;
        if (state.sourceType === 'PRV') {
            return codes.some(function (code) { return codeContains(job.jobEmpTpCd, code); });
        }
        var employmentText = normalizeText(job.empTpNm);
        var labels = {
            R1010: ['정규직'], R1020: ['계약직'], R1030: ['무기계약직'],
            R1040: ['비정규직'], R1050: ['청년인턴'], R1060: ['청년인턴체험형'], R1070: ['청년인턴채용형']
        };
        return codes.some(function (code) {
            if (codeContains(job.jobEmpTpCd, code)) return true;
            return (labels[code] || [code]).some(function (label) {
                return employmentText.indexOf(normalizeText(label)) !== -1;
            });
        });
    }

    function normalizeText(value) {
        return String(value || '').replace(/\s|\(|\)|·|-/g, '').toLowerCase();
    }

    function codeContains(value, code) {
        return String(value || '').split(',').map(function (item) {
            return item.trim();
        }).indexOf(code) !== -1;
    }

    function jobaba276MatchesNcs(ncsCd, jobabaCmmn276Cd) {
        var codes = NCS_JOBABA_276[ncsCd] || [];
        return codes.indexOf(String(jobabaCmmn276Cd || '')) !== -1;
    }

    function getCommonCodeLabel(group, code) {
        return COMMON_CODES[group] && COMMON_CODES[group][code] ? COMMON_CODES[group][code] : code;
    }

    function parseSalaryAmount(value) {
        var match = String(value || '').replace(/,/g, '').match(/\d+/);
        return match ? parseInt(match[0], 10) : 0;
    }

    function updateFilterSummary(filterState, sourceType) {
        filterState = filterState || state;
        sourceType = sourceType || state.sourceType;
        var parts = [];
        if (sourceType === 'PRV') {
            if (filterState.prvJobCds.length)    parts.push('직종 ' + filterState.prvJobCds.length + '개');
            if (filterState.prvEmpTpCds.length)  parts.push('고용형태: ' + filterState.prvEmpTpCds.map(function (c) { return getCommonCodeLabel('prvEmpTp', c); }).join('/'));
            if (filterState.prvCareerCds.length) parts.push('경력: ' + filterState.prvCareerCds.map(function (c) { return getCommonCodeLabel('prvCareer', c); }).join('/'));
            if (filterState.prvEduCds.length)    parts.push('학력: ' + filterState.prvEduCds.map(function (c) { return getCommonCodeLabel('prvEdu', c); }).join('/'));
            if (!filterState.salaryNoCondition)  parts.push(formatSalaryFilterSummary(filterState));
        } else {
            if (filterState.pubNcsCds.length)    parts.push('직종(NCS) ' + filterState.pubNcsCds.length + '개');
            if (filterState.pubEmpTpCds.length)  parts.push('고용형태: ' + filterState.pubEmpTpCds.map(function (c) { return getCommonCodeLabel('empTp', c); }).join('/'));
            if (filterState.pubCareerCds.length) parts.push('경력: ' + filterState.pubCareerCds.map(function (c) { return getCommonCodeLabel('career', c); }).join('/'));
            if (filterState.pubEduCds.length)    parts.push('학력: ' + filterState.pubEduCds.map(function (c) { return getCommonCodeLabel('edubg', c); }).join('/'));
        }
        $filterSummary.innerHTML = '';
        if (!parts.length) {
            $filterSummary.classList.add('is-empty');
            $filterSummary.textContent = '검색조건을 선택해 주세요.';
            return;
        }
        $filterSummary.classList.remove('is-empty');
        parts.forEach(function (part) {
            var tag = document.createElement('span');
            tag.className = 'filter-summary-tag';
            tag.textContent = part;
            $filterSummary.appendChild(tag);
        });
    }

    function updateFilterSummaryPreview() {
        var activeFilterTab = document.querySelector('.filter-src-tab-active');
        var previewState = {
            pubNcsCds: getCheckedValues('pubNcs'),
            pubEmpTpCds: getCheckedValues('pubEmpTp'),
            pubCareerCds: getCheckedValues('pubCareer'),
            pubEduCds: getCheckedValues('pubEdu'),
            prvJobCds: getCheckedValues('prvJob'),
            prvEmpTpCds: getCheckedValues('prvEmpTp'),
            prvCareerCds: getCheckedValues('prvCareer'),
            prvEduCds: getCheckedValues('prvEdu'),
            salaryNoCondition: !$salaryNoCondition || $salaryNoCondition.checked,
            salaryType: $salaryType ? $salaryType.value : '',
            salaryMin: $salaryMin ? $salaryMin.value.trim() : '',
            salaryMax: $salaryMax ? $salaryMax.value.trim() : ''
        };
        updateFilterSummary(previewState, activeFilterTab ? activeFilterTab.dataset.src : state.sourceType);
    }

    /* ─── 상세 닫기 ─── */
    $detailCloseBtn.addEventListener('click', function () { $jobDetail.classList.add('hidden'); });

    if ($mobileMapViewBtn) {
        $mobileMapViewBtn.addEventListener('click', function () { setMobileView('map'); });
    }
    if ($mobileListViewBtn) {
        $mobileListViewBtn.addEventListener('click', function () { setMobileView('list'); });
    }

    /* ─── GPS 위치 버튼 ─── */
    $myLocationBtn.addEventListener('click', goToMyLocation);
    if ($nearMeJobsBtn) $nearMeJobsBtn.addEventListener('click', goToMyLocation);
    $jobList.addEventListener('scroll', handleJobListScroll);
    if ($radiusSelect) {
        $radiusSelect.addEventListener('change', function () {
            setRadiusKm(parseInt(this.value, 10) || 5);
            applyRadiusToMap();
        });
    }
    var $mapContainer = $('mapContainer');
    if ($mapContainer) {
        $mapContainer.addEventListener('click', function (e) {
            var markerEl = e.target.closest('.job-marker');
            if (!markerEl) return;
            var marker = state.markers.find(function (m) { return m.markerId === markerEl.dataset.id; });
            if (!marker && markerEl.dataset.id) {
                marker = state.markers[parseInt(markerEl.dataset.id.replace('group-', ''), 10)];
            }
            if (!marker) return;
            e.preventDefault();
            e.stopPropagation();
            marker.el = markerEl;
            selectMarker(marker);
        }, true);
    }
    document.addEventListener('click', function (e) {
        if (!state.markerPopoverEl) return;
        if (e.target.closest('.marker-job-popover') ||
            e.target.closest('.job-marker') ||
            e.target.closest('.local-job-marker')) return;
        hideMarkerJobPopover();
    });

    function applyRadiusToMap() {
        if (!state.mapReady || !state.map) {
            loadJobs();
            return;
        }
        var levels = { 5: 7, 10: 8, 20: 9 };
        state.map.setLevel(levels[state.radiusKm] || 7);
        setTimeout(loadJobs, 0);
    }

    function setRadiusKm(value) {
        state.radiusKm = value;
        if ($radiusSelect) $radiusSelect.value = String(value);
    }

    function goToMyLocation() {
        if (!navigator.geolocation) { showToast('위치 서비스를 지원하지 않는 브라우저입니다.'); return; }
        showLoading(true);
        navigator.geolocation.getCurrentPosition(
            function (pos) {
                state.userLat = pos.coords.latitude;
                state.userLng = pos.coords.longitude;
                if (state.mapReady && state.map) {
                    state.map.setCenter(new kakao.maps.LatLng(state.userLat, state.userLng));
                    state.map.setLevel(7);
                } else {
                    loadJobs();
                    showToast('지도 없이 현재 위치 기준 목록을 갱신합니다.');
                }
                showLoading(false);
                // idle 이벤트가 자동으로 loadJobs() 호출
            },
            function () { showLoading(false); showToast('위치를 가져올 수 없습니다.'); }
        );
    }

    /* ─── 확대/축소 버튼 ─── */
    $zoomInBtn.addEventListener('click', function () {
        if (!state.mapReady || !state.map) { showToast('지도 로딩 후 사용할 수 있습니다.'); return; }
        var lv = state.map.getLevel();
        if (lv > 1) state.map.setLevel(lv - 1);
    });
    $zoomOutBtn.addEventListener('click', function () {
        if (!state.mapReady || !state.map) { showToast('지도 로딩 후 사용할 수 있습니다.'); return; }
        var lv = state.map.getLevel();
        if (lv < 14) state.map.setLevel(lv + 1);
    });

    /* ─── 지도 위치 라벨 업데이트 ─── */
    function updateLocationLabel() {
        if (!state.mapReady || !state.map || !window.kakao || !kakao.maps.services) return;
        if (state.locationLabelOverride) {
            $currentLocationName.textContent = state.locationLabelOverride;
            return;
        }
        var center = state.map.getCenter();
        var gc = new kakao.maps.services.Geocoder();
        gc.coord2RegionCode(center.getLng(), center.getLat(), function (result, status) {
            if (status === kakao.maps.services.Status.OK) {
                var region = result[0];
                $currentLocationName.textContent = region.region_2depth_name || region.region_1depth_name || '경기도';
            }
        });
    }

    /* ─── 위치 재선택 모달 ─── */
    function openLocReselect() {
        renderSidoList();
        renderSubwayCityOptions();
        resetSubwaySelection();
        $locReselectModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }
    function closeLocReselect() {
        $locReselectModal.classList.add('hidden');
        document.body.style.overflow = '';
    }

    if ($locationReselectBtn) $locationReselectBtn.addEventListener('click', openLocReselect);
    $locReselectOverlay.addEventListener('click', closeLocReselect);
    $locReselectCloseBtn.addEventListener('click', closeLocReselect);
    $locReselectCancelBtn.addEventListener('click', closeLocReselect);

    // 탭 전환
    document.querySelectorAll('.loc-tab').forEach(function (tab) {
        tab.addEventListener('click', function () {
            document.querySelectorAll('.loc-tab').forEach(function (t) { t.classList.remove('active'); });
            this.classList.add('active');
            var tabName = this.dataset.tab;
            $('tabRegion').classList.toggle('hidden', tabName !== 'region');
            $('tabSubway').classList.toggle('hidden', tabName !== 'subway');
        });
    });

    // 시도 목록 렌더링
    function renderSidoList() {
        $sidoList.innerHTML = '';
        Object.keys(REGION_DATA).forEach(function (sido) {
            var li = document.createElement('li');
            li.className = 'region-item' + (state.selectedSido === sido ? ' active' : '');
            li.textContent = sido;
            li.addEventListener('click', function () {
                state.selectedSido = sido;
                document.querySelectorAll('#sidoList .region-item').forEach(function (el) { el.classList.remove('active'); });
                li.classList.add('active');
                renderSigunguList(sido);
            });
            $sidoList.appendChild(li);
        });
        if (state.selectedSido) renderSigunguList(state.selectedSido);
        else renderSigunguList(Object.keys(REGION_DATA)[0]);
    }

    function renderSigunguList(sido) {
        state.selectedSido = sido;
        $sigunguList.innerHTML = '';
        (REGION_DATA[sido] || []).forEach(function (gu) {
            var li = document.createElement('li');
            li.className = 'region-item' + (state.selectedSigungu === gu ? ' selected-gu' : '');
            li.textContent = gu;
            li.addEventListener('click', function () {
                document.querySelectorAll('#sigunguList .region-item').forEach(function (el) { el.classList.remove('selected-gu'); });
                li.classList.add('selected-gu');
                state.selectedSigungu = gu;
            });
            $sigunguList.appendChild(li);
        });
    }

    // 역세권 도시 옵션
    function renderSubwayCityOptions() {
        $subwayCitySelect.innerHTML = '<option value="">도시 선택</option>';
        Object.keys(SUBWAY_DATA).forEach(function (city) {
            var opt = document.createElement('option');
            opt.value = city; opt.textContent = city;
            $subwayCitySelect.appendChild(opt);
        });
    }

    function resetSubwaySelection() {
        state.selectedStation = null;
        $subwayCitySelect.value = '';
        $subwayLineSelect.innerHTML = '<option value="">호선 선택</option>';
        $stationGrid.innerHTML = '';
    }

    $subwayCitySelect.addEventListener('change', function () {
        var city = this.value;
        $subwayLineSelect.innerHTML = '<option value="">호선 선택</option>';
        $stationGrid.innerHTML = '';
        state.selectedStation = null;
        if (!city) return;
        Object.keys(SUBWAY_DATA[city]).forEach(function (line) {
            var opt = document.createElement('option');
            opt.value = line; opt.textContent = line;
            $subwayLineSelect.appendChild(opt);
        });
    });

    $subwayLineSelect.addEventListener('change', function () {
        var city = $subwayCitySelect.value;
        var line = this.value;
        $stationGrid.innerHTML = '';
        state.selectedStation = null;
        if (!city || !line) return;
        (SUBWAY_DATA[city][line] || []).forEach(function (st) {
            var div = document.createElement('div');
            div.className = 'station-item';
            div.textContent = st;
            div.addEventListener('click', function () {
                document.querySelectorAll('.station-item').forEach(function (el) { el.classList.remove('active'); });
                div.classList.add('active');
                state.selectedStation = st;
            });
            $stationGrid.appendChild(div);
        });
    });

    // 위치 적용
    $locReselectApplyBtn.addEventListener('click', function () {
        var tabActive = document.querySelector('.loc-tab.active').dataset.tab;
        if (tabActive === 'region') {
            if (!state.selectedSigungu && !state.selectedSido) { showToast('지역을 선택해 주세요.'); return; }
            if (!state.mapReady || !state.map || !window.kakao || !kakao.maps.services) {
                $currentLocationName.textContent = state.selectedSigungu || state.selectedSido;
                closeLocReselect();
                loadJobs();
                showToast('지도 없이 선택 지역 기준 목록을 갱신합니다.');
                return;
            }
            var query = state.selectedSigungu || state.selectedSido;
            if (state.selectedSido && state.selectedSigungu) query = state.selectedSido + ' ' + state.selectedSigungu;
            var geocoder = new kakao.maps.services.Geocoder();
            geocoder.addressSearch(query, function (result, status) {
                if (status === kakao.maps.services.Status.OK) {
                    state.locationLabelOverride = '';
                    var r = result[0];
                    setRadiusKm(5);
                    moveMapAndReload(r.y, r.x, 7);
                    $currentLocationName.textContent = state.selectedSigungu || state.selectedSido;
                } else { showToast('해당 지역을 지도에서 찾을 수 없습니다.'); }
            });
        } else {
            if (!state.selectedStation) { showToast('역을 선택해 주세요.'); return; }
            if (!state.mapReady || !state.map || !window.kakao || !kakao.maps.services) {
                $currentLocationName.textContent = state.selectedStation + '역';
                closeLocReselect();
                loadJobs();
                showToast('지도 없이 선택 역 기준 목록을 갱신합니다.');
                return;
            }
            var stationQuery = state.selectedStation + '역';
            var places = new kakao.maps.services.Places();
            places.keywordSearch(stationQuery, function (result, status) {
                if (status === kakao.maps.services.Status.OK && result.length) {
                    state.locationLabelOverride = state.selectedStation + '역';
                    var r2 = result[0];
                    setRadiusKm(5);
                    moveMapAndReload(r2.y, r2.x, 6);
                    $currentLocationName.textContent = state.selectedStation + '역';
                    closeLocReselect();
                } else {
                    var gc2 = new kakao.maps.services.Geocoder();
                    gc2.addressSearch(stationQuery, function (addrResult, addrStatus) {
                        if (addrStatus === kakao.maps.services.Status.OK && addrResult.length) {
                            state.locationLabelOverride = state.selectedStation + '역';
                            var r3 = addrResult[0];
                            setRadiusKm(5);
                            moveMapAndReload(r3.y, r3.x, 6);
                            $currentLocationName.textContent = state.selectedStation + '역';
                            closeLocReselect();
                        } else {
                            showToast('역을 찾을 수 없습니다.');
                        }
                    });
                }
            });
            return;
        }
        closeLocReselect();
    });

    /* ─── 위치 권한 모달 ─── */
    $locationAllowBtn.addEventListener('click', function () {
        sessionStorage.setItem('location_asked', '1');
        $locationModal.classList.add('hidden');
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                function (pos) {
                    state.userLat = pos.coords.latitude;
                    state.userLng = pos.coords.longitude;
                    if (state.mapReady && state.map) {
                        state.map.setCenter(new kakao.maps.LatLng(state.userLat, state.userLng));
                        state.map.setLevel(7);
                    } else {
                        loadJobs();
                    }
                },
                function () {}
            );
        }
    });
    $locationDenyBtn.addEventListener('click', function () {
        sessionStorage.setItem('location_asked', '1');
        $locationModal.classList.add('hidden');
    });

    /* ─── 유틸리티 ─── */
    function showListUpdating(show) {
        if ($jobPanel) $jobPanel.classList.toggle('is-updating', show);
    }

    function showLoading(show) { $loadingOverlay.classList.toggle('hidden', !show); }

    function isPublicJob(job) {
        return job.sourceType === '공공';
    }

    function getJobKindLabel(job) {
        return isPublicJob(job) ? '공공' : '민간';
    }

    function moveMapAndReload(lat, lng, level) {
        if (!state.mapReady || !state.map) return;
        state.map.setLevel(level);
        state.map.setCenter(new kakao.maps.LatLng(parseFloat(lat), parseFloat(lng)));
        setTimeout(loadJobs, 0);
    }

    var _toastTimer;
    function showToast(msg) {
        clearTimeout(_toastTimer);
        $toast.textContent = msg;
        $toast.classList.remove('hidden');
        _toastTimer = setTimeout(function () { $toast.classList.add('hidden'); }, 2800);
    }

    function escapeHtml(str) {
        return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }

    function getSafeExternalUrl(value) {
        if (!value) return '';
        try {
            var url = new URL(String(value), window.location.origin);
            return url.protocol === 'http:' || url.protocol === 'https:' ? url.href : '';
        } catch (e) {
            return '';
        }
    }

    function formatCloseDt(dt) {
        if (!dt) return '';
        if (String(dt).trim() === '상시채용') return '상시채용';
        var parsed = parseCloseDate(dt);
        if (!parsed) return formatDateOnly(dt);
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        var diff = Math.ceil((parsed - today) / 86400000);
        if (diff < 0) return '마감';
        if (diff === 0) return 'D-Day';
        if (diff <= 7) return 'D-' + diff;
        return formatDateOnly(dt) + ' 마감';
    }

    function formatDateOnly(dt) {
        if (!dt) return '';
        if (String(dt).trim() === '상시채용') return '상시채용';
        var parsed = parseCloseDate(dt);
        if (parsed) {
            return parsed.getFullYear() + '.' +
                String(parsed.getMonth() + 1).padStart(2, '0') + '.' +
                String(parsed.getDate()).padStart(2, '0');
        }
        return String(dt).trim().replace(/-/g, '.');
    }

    function formatDday(dt) {
        if (!dt || String(dt).trim() === '상시채용') return '';
        var parsed = parseCloseDate(dt);
        if (!parsed) return '';
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        var diff = Math.ceil((parsed - today) / 86400000);
        if (diff < 0) return '마감';
        if (diff === 0) return 'D-Day';
        return 'D-' + diff;
    }

    function formatSal(tp, amt) {
        if (!amt) return '';
        var type = String(tp || '').trim();
        var amount = String(amt).trim();
        if (amount === '협의') return '급여협의';
        if (type && /^\d[\d,]*(?:\s*~\s*\d[\d,]*)?$/.test(amount)) {
            var unit = type === '연봉' || type === '월급' ? '만원' : '원';
            amount = amount.split('~').map(function (value) {
                return Number(value.replace(/,/g, '').trim()).toLocaleString('ko-KR') + unit;
            }).join(' ~ ');
        }
        return (type + ' ' + amount).trim();
    }

    function isClosingSoon(dt) {
        if (!dt || String(dt).trim() === '상시채용') return false;
        var parsed = parseCloseDate(dt);
        if (!parsed) return false;
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        var diff = (parsed - today) / 86400000;
        return diff >= 0 && diff <= 7;
    }

    function isExpiredCloseDt(dt) {
        var text = String(dt || '').trim();
        if (!text || text === '상시채용' || text === '채용시까지') return false;
        var parsed = parseCloseDate(text);
        if (!parsed) return false;
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        return parsed < today;
    }

    function parseCloseDate(dt) {
        var text = String(dt || '').trim();
        var match = text.match(/^(\d{4})[-.]?(\d{1,2})[-.]?(\d{1,2})$/);
        if (!match) return null;
        var parsed = new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
        parsed.setHours(0, 0, 0, 0);
        if (parsed.getFullYear() !== Number(match[1]) ||
                parsed.getMonth() !== Number(match[2]) - 1 ||
                parsed.getDate() !== Number(match[3])) {
            return null;
        }
        return parsed;
    }

    function distance(lat1, lng1, lat2, lng2) {
        if (!lat1 || !lat2) return 9999999;
        var R = 6371000;
        var dLat = (lat2 - lat1) * Math.PI / 180;
        var dLng = (lng2 - lng1) * Math.PI / 180;
        var a = Math.sin(dLat/2)*Math.sin(dLat/2) +
                Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*
                Math.sin(dLng/2)*Math.sin(dLng/2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    }

    function formatDist(m) {
        return m < 1000 ? Math.round(m) + 'm' : (m/1000).toFixed(1) + 'km';
    }

    /* ─── URL 파라미터 처리 (분양 페이지 연동) ─── */
    var _urlParams   = new URLSearchParams(window.location.search);
    var _initLat     = parseFloat(_urlParams.get('lat'))  || DEFAULT_LAT;
    var _initLng     = parseFloat(_urlParams.get('lng'))  || DEFAULT_LNG;
    var _initName    = _urlParams.get('name') ? decodeURIComponent(_urlParams.get('name')) : null;
    var _initLevel   = _initName ? 7 : DEFAULT_LEVEL;
    if (_initName && $currentLocationName) {
        $currentLocationName.textContent = _initName;
    }

    /* ─── 초기화 ─── */
    populatePanelSelects();
    syncModalFilterTabs();
    setMobileView('map');
    if (window.lucide && typeof window.lucide.createIcons === 'function') {
        window.lucide.createIcons();
    }

    /* ─── 진입점 ─── */
    loadKakaoSdk()
        .then(function () { initMap(_initLat, _initLng, _initLevel); })
        .catch(function () {
            initMapFallback();
            showToast('지도 로딩에 실패해 목록 모드로 전환했습니다.');
        });

    if (sessionStorage.getItem('location_asked')) {
        $locationModal.classList.add('hidden');
    }

})();
