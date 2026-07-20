(function (root, factory) {
    'use strict';

    if (typeof module === 'object' && module.exports) {
        module.exports = factory();
        return;
    }

    root.JobabaMapKakaoKey = factory();
})(typeof window !== 'undefined' ? window : globalThis, function () {
    'use strict';

    function selectKakaoJsKey(configuredKey) {
        if (typeof configuredKey !== 'string') {
            return '';
        }
        return configuredKey.trim();
    }

    return {
        selectKakaoJsKey: selectKakaoJsKey
    };
});
