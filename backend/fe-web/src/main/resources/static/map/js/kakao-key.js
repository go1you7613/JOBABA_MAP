(function (root, factory) {
    'use strict';

    if (typeof module === 'object' && module.exports) {
        module.exports = factory();
        return;
    }

    root.JobabaMapKakaoKey = factory();
})(typeof window !== 'undefined' ? window : globalThis, function () {
    'use strict';

    var KAKAO_JS_KEYS = {
        local: '95702b4427df8e2707e729267c908b17',
        development: 'fadae118705fddee31ebf7a794a459ea'
    };

    var DEVELOPMENT_HOSTS = {
        '43.203.21.169': true,
        'quant-eval.tanauxd.com': true,
        'jobaba-map.tanauxd.com': true
    };

    function selectKakaoJsKey(href) {
        var url;

        try {
            url = new URL(href || '');
        } catch (e) {
            return KAKAO_JS_KEYS.local;
        }

        if (DEVELOPMENT_HOSTS[url.hostname]) {
            return KAKAO_JS_KEYS.development;
        }

        return KAKAO_JS_KEYS.local;
    }

    return {
        KAKAO_JS_KEYS: KAKAO_JS_KEYS,
        selectKakaoJsKey: selectKakaoJsKey
    };
});
