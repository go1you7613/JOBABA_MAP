package kr.go.tkjf.usr.map.client;

public class MapBizHttpException extends RuntimeException {

    private final int statusCode;

    MapBizHttpException(int statusCode) {
        this.statusCode = statusCode;
    }

    public int getStatusCode() {
        return statusCode;
    }
}
