# HAMerger

HAMerger is simple script built with [node.js](http://nodejs.org/) and inspired by [Josip Lazić](http://lazic.info/josip/post/splitting-haproxy-config/) article.

HAMerger allows you to merge multiple configuration files into a single one readable by HaProxy. This script is able to concat configuration of a same section from different files into the right place.

# Usage

Below are the available options :

```
 Usage: ./hamerger.js [options] <configPath>

  Options:

    -V, --version          output the version number
    -f, --filter <filter>  The filter to apply on config file. Default to ".cfg$"
    -p, --print            Print merged config
    -o, --output <path>    The output file to write merged config
    -v, --verbose          Print logs
    -h, --help             output usage information
```

# Example

Assuming the config files and structure below, you can use the script like this : `/hamerger.js /etc/haproxy/conf.d -o /etc/haproxy/haproxy.cfg -v`.

```
/etc/haproxy/conf.d/
├── 000-global.cfg
├── 001-vm1.cfg
├── 002-vm2.cfg
└── 999-default.cfg
```

/etc/haproxy/conf.d/000-global.cfg:
```
frontend dev
    bind 127.0.0.1:80
```

/etc/haproxy/conf.d/001-vm1.cfg:
```
frontend dev
    acl is_vm1 hdr(host) -i vm1.mycompany.com
    use_backend vm1_backend if is_vm1

backend vm1_backend
    server vm1 172.21.0.11:80 check
    ...
```

/etc/haproxy/conf.d/001-vm2.cfg:
```
frontend dev
    acl is_vm2 hdr(host) -i vm2.mycompany.com
    use_backend vm2_backend if is_vm2

backend vm2_backend
    server vm1 172.21.0.12:80 check
    ...
```

/etc/haproxy/conf.d/999-default.cfg:
```
frontend dev
    default_backend fallback_backend

backend fallback_backend
    server fallback 172.21.0.1:80 check
    ...
```

The generated file : /etc/haproxy/haproxy.cfg
```
frontend dev
    bind 127.0.0.1:80

    acl is_vm1 hdr(host) -i vm1.mycompany.com
    use_backend vm1_backend if is_vm1

    acl is_vm2 hdr(host) -i vm2.mycompany.com
    use_backend vm2_backend if is_vm2

    default_backend fallback_backend

backend vm1_backend
    server vm1 172.21.0.11:80 check
    ...

backend vm2_backend
    server vm2 172.21.0.12:80 check
    ...

backend fallback_backend
    server fallback 172.21.0.1:80 check
    ...
```