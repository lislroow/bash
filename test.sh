function test1 {
  curl -vX GET http://localhost/auth-api/v1/mybatis-crud/scientists?page=2 \
    -H 'Authorization: bearer f1a0add593ed43fb9c10828da73bbe64' \
    | jq
}

function test2 {
  curl -sX POST http://localhost/auth-api/v1/token/refresh \
    -H 'Content-Type: application/json' \
    -d '{"rtkUuid": "8418dcd2a6bd4b6fa699c3f80eeffd50"}' \
    | jq
}

test1
