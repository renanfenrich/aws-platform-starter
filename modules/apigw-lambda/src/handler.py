import json


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }


def lambda_handler(event, context):
    route_key = event.get("routeKey", "")

    if route_key == "GET /health":
        return _response(200, {"status": "ok"})

    if route_key == "POST /echo":
        http_context = event.get("requestContext", {}).get("http", {})
        return _response(
            200,
            {
                "routeKey": route_key,
                "requestId": event.get("requestContext", {}).get("requestId"),
                "method": http_context.get("method"),
                "path": http_context.get("path") or event.get("rawPath"),
                "sourceIp": http_context.get("sourceIp"),
                "queryStringParameters": event.get("queryStringParameters"),
                "body": event.get("body"),
                "isBase64Encoded": event.get("isBase64Encoded", False),
            },
        )

    return _response(404, {"error": "not_found"})
