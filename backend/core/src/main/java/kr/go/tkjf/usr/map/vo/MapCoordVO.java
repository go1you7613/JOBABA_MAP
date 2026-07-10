package kr.go.tkjf.usr.map.vo;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

public class MapCoordVO {
    @NotBlank
    @Size(max = 50)
    @Pattern(regexp = "[A-Za-z0-9_-]+")
    private String wantedAuthNo;   // FK (tb_empmn_worknet_api)

    @NotBlank
    @Pattern(regexp = "-?\\d{1,3}(\\.\\d{1,15})?")
    private String lat;            // 위도

    @NotBlank
    @Pattern(regexp = "-?\\d{1,3}(\\.\\d{1,15})?")
    private String lng;            // 경도

    @Pattern(regexp = "|Y|N")
    private String geocodeYn;      // 변환완료여부 Y/N

    public String getWantedAuthNo() {
        return wantedAuthNo;
    }

    public void setWantedAuthNo(String wantedAuthNo) {
        this.wantedAuthNo = wantedAuthNo;
    }

    public String getLat() {
        return lat;
    }

    public void setLat(String lat) {
        this.lat = lat;
    }

    public String getLng() {
        return lng;
    }

    public void setLng(String lng) {
        this.lng = lng;
    }

    public String getGeocodeYn() {
        return geocodeYn;
    }

    public void setGeocodeYn(String geocodeYn) {
        this.geocodeYn = geocodeYn;
    }
}
