Dockerfile to start vstart ceph inside fedora

To build

```
docker build --no-cache -t ceph-rpm-fedora .
```

To start

```
docker run -it ceph-rpm-fedora
```
