# basic-http-endpoint

Goal is to strip down the orginal example from swift nio http server to better understand how the HTTP Parser part works.

how to test?
```bash
curl 127.0.0.1:8080/ -vv
```

expected response

```
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to 127.0.0.1 (127.0.0.1) port 8080 (#0)
> GET / HTTP/1.1
> Host: 127.0.0.1:8080
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< content-length: 12
<
* Connection #0 to host 127.0.0.1 left intact
Hello World!
```
