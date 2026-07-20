package kr.go.tkjf.usr.map.vo;

public class MapApiResponse<T> {

    private T body;

    public MapApiResponse() {
    }

    public MapApiResponse(T body) {
        this.body = body;
    }

    public T getBody() {
        return body;
    }

    public void setBody(T body) {
        this.body = body;
    }
}
