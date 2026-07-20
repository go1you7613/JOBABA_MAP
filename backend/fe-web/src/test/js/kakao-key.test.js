const assert = require('node:assert/strict');
const test = require('node:test');

const { selectKakaoJsKey } = require('../../main/resources/static/map/js/kakao-key.js');

test('uses the Kakao JavaScript key supplied by server configuration', () => {
  assert.equal(selectKakaoJsKey(' configured-key '), 'configured-key');
});

test('returns an empty value when the key is not configured', () => {
  assert.equal(selectKakaoJsKey(''), '');
  assert.equal(selectKakaoJsKey(undefined), '');
});
