package kr.go.tkjf.usr.map.vo;

import javax.validation.Valid;
import javax.validation.constraints.NotNull;

public class MapApiRequest<T> {

    @NotNull
    @Valid
    private T body;

    public MapApiRequest() {
    }

    public MapApiRequest(T body) {
        this.body = body;
    }

    public T getBody() {
        return body;
    }

    public void setBody(T body) {
        this.body = body;
    }
}
