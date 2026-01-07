<details>
<summary>caddy: letencrypt 인증서 발급 로그 → (정상)</summary>

```json
Jan 05 22:28:26 develop caddy[3129]: {"level":"info","ts":1767619706.854623,"msg":"trying to solve challenge","identifier":"code.dlog.my","challenge_type":"tls-alpn-01","ca":"https://acme-v02.api.letsencrypt.org/directory"}
Jan 05 22:28:27 develop caddy[3129]: {"level":"info","ts":1767619707.7143872,"logger":"tls","msg":"served key authentication certificate","server_name":"code.dlog.my","challenge":"tls-alpn-01","remote":"172.28.200.1:52859","distributed":false}
Jan 05 22:28:28 develop caddy[3129]: {"level":"info","ts":1767619708.2426596,"logger":"tls","msg":"served key authentication certificate","server_name":"code.dlog.my","challenge":"tls-alpn-01","remote":"172.28.200.1:55256","distributed":false}
Jan 05 22:28:28 develop caddy[3129]: {"level":"info","ts":1767619708.4677136,"logger":"tls","msg":"served key authentication certificate","server_name":"code.dlog.my","challenge":"tls-alpn-01","remote":"172.28.200.1:55257","distributed":false}
Jan 05 22:28:28 develop caddy[3129]: {"level":"info","ts":1767619708.6282117,"logger":"tls","msg":"served key authentication certificate","server_name":"code.dlog.my","challenge":"tls-alpn-01","remote":"172.28.200.1:55258","distributed":false}
Jan 05 22:28:28 develop caddy[3129]: {"level":"info","ts":1767619708.9261951,"logger":"tls","msg":"served key authentication certificate","server_name":"code.dlog.my","challenge":"tls-alpn-01","remote":"172.28.200.1:55259","distributed":false}
Jan 05 22:28:30 develop caddy[3129]: {"level":"info","ts":1767619710.9926841,"msg":"authorization finalized","identifier":"code.dlog.my","authz_status":"valid"}
Jan 05 22:28:30 develop caddy[3129]: {"level":"info","ts":1767619710.9927933,"msg":"validations succeeded; finalizing order","order":"https://acme-v02.api.letsencrypt.org/acme/order/2936352046/466285600676"}
Jan 05 22:28:33 develop caddy[3129]: {"level":"info","ts":1767619713.7199697,"msg":"got renewal info","names":["code.dlog.my"],"window_start":1772723645,"window_end":1772879095,"selected_time":1772852430,"recheck_after":1767641313.7199423,"explanation_url":""}
Jan 05 22:28:34 develop caddy[3129]: {"level":"info","ts":1767619714.4713502,"msg":"got renewal info","names":["code.dlog.my"],"window_start":1772723645,"window_end":1772879095,"selected_time":1772868553,"recheck_after":1767641314.471326,"explanation_url":""}
Jan 05 22:28:34 develop caddy[3129]: {"level":"info","ts":1767619714.4715023,"msg":"successfully downloaded available certificate chains","count":2,"first_url":"https://acme-v02.api.letsencrypt.org/acme/cert/0653a703e8b57bddc41864c8859d2a55bb94"}
Jan 05 22:28:34 develop caddy[3129]: {"level":"info","ts":1767619714.477102,"logger":"tls.obtain","msg":"certificate obtained successfully","identifier":"code.dlog.my","issuer":"acme-v02.api.letsencrypt.org-directory"}
Jan 05 22:28:34 develop caddy[3129]: {"level":"info","ts":1767619714.4772775,"logger":"tls.obtain","msg":"releasing lock","identifier":"code.dlog.my"}
```
</details>

