package kr.go.tkjf.usr.map.vo;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

@Getter
@Setter
@NoArgsConstructor
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
}
