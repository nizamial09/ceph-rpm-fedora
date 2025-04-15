Dockerfile to start vstart ceph inside fedora

To build

```
docker build --no-cache -t ceph-rpm-fedora .
```

To start

```
docker run -it ceph-rpm-fedora
```


To serve the mgr modules from local, just mount the pybind folder
```
docker run -v /home/nia/projects/ceph/src/pybind/mgr:/usr/share/ceph/mgr -it ceph-rpm-fedora
```
