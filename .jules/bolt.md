## 2025-05-10 - Parallelize C/C++ native builds in installation scripts
**Learning:** Shell installation scripts building native binaries/toolchains default to single-threaded `make`, causing slow build times on multi-core mobile CPUs.
**Action:** Always check `nproc` and invoke `make -j"$NPROC"` with fallback to accelerate native dependency builds.

## 2026-08-18 - Check package installation status before calling package manager updates
**Learning:** Executing unconditional package manager update/install commands (`pkg update`, `pkg install`) in setup scripts causes redundant network requests and index updates on every invocation (~15-30s delay).
**Action:** Pre-check whether required packages are already installed (e.g. using `dpkg-query`) and skip network-bound package manager commands when dependencies exist.
