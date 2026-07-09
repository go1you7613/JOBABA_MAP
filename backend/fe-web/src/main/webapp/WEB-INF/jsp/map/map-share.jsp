<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>일자리 맵 서비스 | 경기도일자리재단</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --primary:    #1E5FBF;
            --primary-dk: #154da3;
            --gray-100:   #f8f9fa;
            --gray-200:   #eeeff1;
            --gray-300:   #dee0e3;
            --gray-700:   #374151;
            --white:      #ffffff;
        }
        html, body {
            min-height: 100%;
            background: var(--gray-100);
            font-family: 'Malgun Gothic', 'Apple SD Gothic Neo', sans-serif;
            font-size: 14px;
            color: var(--gray-700);
        }
        body {
            padding: 28px;
        }
        .container {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(132px, 1fr));
            gap: 14px;
            max-width: 1180px;
            margin: 0 auto;
        }
        .city-item {
            display: block;
            min-height: 116px;
            padding: 12px;
            border: 1px solid var(--gray-200);
            border-radius: 8px;
            background: var(--white);
            box-shadow: 0 1px 4px rgba(17, 24, 39, .06);
            transition: border-color .15s, box-shadow .15s, transform .15s;
        }
        .city-item:hover,
        .city-item:focus-visible {
            border-color: var(--primary);
            box-shadow: 0 4px 14px rgba(30, 95, 191, .14);
            outline: none;
            transform: translateY(-1px);
        }
        .city-logo-wrap {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 100%;
            height: 70px;
        }
        .city-logo {
            display: block;
            max-width: 100%;
            max-height: 64px;
            object-fit: contain;
        }
        .city-label {
            display: block;
            margin-top: 10px;
            color: var(--primary-dk);
            font-size: 13px;
            font-weight: 700;
            line-height: 1.2;
            text-align: center;
            letter-spacing: -.2px;
        }
        a {
            color: inherit;
            text-decoration: none;
        }
        @media (max-width: 640px) {
            body { padding: 16px; }
            .container {
                grid-template-columns: repeat(2, minmax(0, 1fr));
                gap: 10px;
            }
            .city-item {
                min-height: 108px;
                padding: 10px;
            }
            .city-logo-wrap { height: 64px; }
            .city-logo { max-height: 58px; }
        }
    </style>
</head>
<body>

<div class="container" aria-label="경기도 시군별 일자리맵 바로가기">
    <a class="city-item" href="/map?lat=37.2636&amp;lng=127.0286&amp;name=수원시" data-name="수원시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/suwon.png" alt="수원시 로고"></span>
        <span class="city-label">수원시</span>
    </a>
    <a class="city-item" href="/map?lat=37.6584&amp;lng=126.8320&amp;name=고양시" data-name="고양시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/goyang.png" alt="고양시 로고"></span>
        <span class="city-label">고양시</span>
    </a>
    <a class="city-item" href="/map?lat=37.2411&amp;lng=127.1776&amp;name=용인시" data-name="용인시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/yongin.png" alt="용인시 로고"></span>
        <span class="city-label">용인시</span>
    </a>
    <a class="city-item" href="/map?lat=37.4201&amp;lng=127.1268&amp;name=성남시" data-name="성남시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/seongnam.png" alt="성남시 로고"></span>
        <span class="city-label">성남시</span>
    </a>
    <a class="city-item" href="/map?lat=37.5035&amp;lng=126.7660&amp;name=부천시" data-name="부천시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/bucheon.png" alt="부천시 로고"></span>
        <span class="city-label">부천시</span>
    </a>
    <a class="city-item" href="/map?lat=37.1995&amp;lng=126.8312&amp;name=화성시" data-name="화성시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/hwaseong.png" alt="화성시 로고"></span>
        <span class="city-label">화성시</span>
    </a>
    <a class="city-item" href="/map?lat=37.6360&amp;lng=127.2165&amp;name=남양주시" data-name="남양주시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/namyangju.png" alt="남양주시 로고"></span>
        <span class="city-label">남양주시</span>
    </a>
    <a class="city-item" href="/map?lat=37.3219&amp;lng=126.8309&amp;name=안산시" data-name="안산시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/ansan.png" alt="안산시 로고"></span>
        <span class="city-label">안산시</span>
    </a>
    <a class="city-item" href="/map?lat=36.9921&amp;lng=127.1127&amp;name=평택시" data-name="평택시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/pyeongtaek.png" alt="평택시 로고"></span>
        <span class="city-label">평택시</span>
    </a>
    <a class="city-item" href="/map?lat=37.3943&amp;lng=126.9568&amp;name=안양시" data-name="안양시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/anyang.png" alt="안양시 로고"></span>
        <span class="city-label">안양시</span>
    </a>
    <a class="city-item" href="/map?lat=37.3802&amp;lng=126.8029&amp;name=시흥시" data-name="시흥시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/siheung.png" alt="시흥시 로고"></span>
        <span class="city-label">시흥시</span>
    </a>
    <a class="city-item" href="/map?lat=37.7599&amp;lng=126.7802&amp;name=파주시" data-name="파주시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/paju.png" alt="파주시 로고"></span>
        <span class="city-label">파주시</span>
    </a>
    <a class="city-item" href="/map?lat=37.6152&amp;lng=126.7156&amp;name=김포시" data-name="김포시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/gimpo.png" alt="김포시 로고"></span>
        <span class="city-label">김포시</span>
    </a>
    <a class="city-item" href="/map?lat=37.7381&amp;lng=127.0338&amp;name=의정부시" data-name="의정부시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/uijeongbu.png" alt="의정부시 로고"></span>
        <span class="city-label">의정부시</span>
    </a>
    <a class="city-item" href="/map?lat=37.4294&amp;lng=127.2550&amp;name=광주시" data-name="광주시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/gwangju.png" alt="광주시 로고"></span>
        <span class="city-label">광주시</span>
    </a>
    <a class="city-item" href="/map?lat=37.4785&amp;lng=126.8647&amp;name=광명시" data-name="광명시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/gwangmyeong.png" alt="광명시 로고"></span>
        <span class="city-label">광명시</span>
    </a>
    <a class="city-item" href="/map?lat=37.5393&amp;lng=127.2149&amp;name=하남시" data-name="하남시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/hanam.png" alt="하남시 로고"></span>
        <span class="city-label">하남시</span>
    </a>
    <a class="city-item" href="/map?lat=37.3617&amp;lng=126.9352&amp;name=군포시" data-name="군포시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/gunpo.png" alt="군포시 로고"></span>
        <span class="city-label">군포시</span>
    </a>
    <a class="city-item" href="/map?lat=37.1498&amp;lng=127.0772&amp;name=오산시" data-name="오산시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/osan.png" alt="오산시 로고"></span>
        <span class="city-label">오산시</span>
    </a>
    <a class="city-item" href="/map?lat=37.2720&amp;lng=127.4350&amp;name=이천시" data-name="이천시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/icheon.png" alt="이천시 로고"></span>
        <span class="city-label">이천시</span>
    </a>
    <a class="city-item" href="/map?lat=37.0080&amp;lng=127.2797&amp;name=안성시" data-name="안성시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/anseong.png" alt="안성시 로고"></span>
        <span class="city-label">안성시</span>
    </a>
    <a class="city-item" href="/map?lat=37.5943&amp;lng=127.1296&amp;name=구리시" data-name="구리시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/guri.png" alt="구리시 로고"></span>
        <span class="city-label">구리시</span>
    </a>
    <a class="city-item" href="/map?lat=37.7853&amp;lng=127.0458&amp;name=양주시" data-name="양주시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/yangju.png" alt="양주시 로고"></span>
        <span class="city-label">양주시</span>
    </a>
    <a class="city-item" href="/map?lat=37.8949&amp;lng=127.2003&amp;name=포천시" data-name="포천시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/pocheon.png" alt="포천시 로고"></span>
        <span class="city-label">포천시</span>
    </a>
    <a class="city-item" href="/map?lat=37.3447&amp;lng=126.9683&amp;name=의왕시" data-name="의왕시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/uiwang.png" alt="의왕시 로고"></span>
        <span class="city-label">의왕시</span>
    </a>
    <a class="city-item" href="/map?lat=37.2983&amp;lng=127.6371&amp;name=여주시" data-name="여주시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/yeoju.png" alt="여주시 로고"></span>
        <span class="city-label">여주시</span>
    </a>
    <a class="city-item" href="/map?lat=37.9037&amp;lng=127.0607&amp;name=동두천시" data-name="동두천시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/dongducheon.png" alt="동두천시 로고"></span>
        <span class="city-label">동두천시</span>
    </a>
    <a class="city-item" href="/map?lat=37.4292&amp;lng=126.9876&amp;name=과천시" data-name="과천시" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/gwacheon.png" alt="과천시 로고"></span>
        <span class="city-label">과천시</span>
    </a>
    <a class="city-item" href="/map?lat=37.4918&amp;lng=127.4876&amp;name=양평군" data-name="양평군" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/yangpyeong.png" alt="양평군 로고"></span>
        <span class="city-label">양평군</span>
    </a>
    <a class="city-item" href="/map?lat=37.8315&amp;lng=127.5099&amp;name=가평군" data-name="가평군" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/gapyeong.png" alt="가평군 로고"></span>
        <span class="city-label">가평군</span>
    </a>
    <a class="city-item" href="/map?lat=38.0964&amp;lng=127.0746&amp;name=연천군" data-name="연천군" onclick="openMap(event, this)">
        <span class="city-logo-wrap"><img class="city-logo" src="/map/images/sigungu/yeoncheon.png" alt="연천군 로고"></span>
        <span class="city-label">연천군</span>
    </a>
</div>

<script>
    function openMap(event, link) {
        event.preventDefault();

        var popup = window.open(
            link.href,
            'jobaba_map_' + link.dataset.name,
            'width=1280,height=800,left=100,top=80,resizable=yes,scrollbars=no'
        );

        if (!popup || popup.closed || typeof popup.closed === 'undefined') {
            alert('팝업이 차단되었습니다.\n브라우저의 팝업 허용 설정 후 다시 시도해 주세요.');
        } else {
            popup.focus();
        }
    }
</script>

</body>
</html>
