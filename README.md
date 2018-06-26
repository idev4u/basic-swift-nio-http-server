# basic-http-endpoint

Goal is to strip down the orginal example from swift nio http server to better understand how the HTTP Parser part works.

## how to test?
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

## Benchmark

Currently this experimental project supports only one connection for benchmarking. Maybe more in the future 🚀.(tbd)
```
bash$ wrk -t1 -c1 -d 10s http://127.0.0.1:8080/
```
result
```
Running 10s test @ http://127.0.0.1:8080/
  1 threads and 1 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   233.23us   34.04us   1.39ms   89.94%
    Req/Sec     4.22k   255.95     4.51k    94.06%
  42454 requests in 10.10s, 2.06MB read
Requests/sec:   4203.21
Transfer/sec:    209.34KB
``
