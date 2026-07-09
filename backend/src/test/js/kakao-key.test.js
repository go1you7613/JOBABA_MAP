const assert = require('node:assert/strict');
const test = require('node:test');

const { selectKakaoJsKey } = require('../../main/resources/static/map/js/kakao-key.js');

test('selects the local Kakao JavaScript key for localhost origins', () => {
  assert.equal(
    selectKakaoJsKey('http://localhost:8080/map/index.html'),
    '95702b4427df8e2707e729267c908b17'
  );
});

test('selects the development Kakao JavaScript key for the personal dev server', () => {
  assert.equal(
    selectKakaoJsKey('http://43.203.21.169:18081/'),
    'fadae118705fddee31ebf7a794a459ea'
  );
});

test('selects the development Kakao JavaScript key for the dev domain', () => {
  assert.equal(
    selectKakaoJsKey('http://quant-eval.tanauxd.com:18081/'),
    'fadae118705fddee31ebf7a794a459ea'
  );
});

test('selects the development Kakao JavaScript key for the Jobaba map dev domain', () => {
  assert.equal(
    selectKakaoJsKey('https://jobaba-map.tanauxd.com/map/index.html'),
    'fadae118705fddee31ebf7a794a459ea'
  );
});
