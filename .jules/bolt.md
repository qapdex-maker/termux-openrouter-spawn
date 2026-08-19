## 2025-05-10 - Parallelize C/C++ native builds in installation scripts
**Learning:** Shell installation scripts building native binaries/toolchains default to single-threaded `make`, causing slow build times on multi-core mobile CPUs.
**Action:** Always check `nproc` and invoke `make -j"$NPROC"` with fallback to accelerate native dependency builds.
