## 2026-08-18 - Pinning Shallow Git Clones to Commit SHAs
**Vulnerability:** Upstream dependency (`bun-termux`) was referenced by branch name (`main`), exposing the installer to supply chain attacks or breaking upstream changes.
**Learning:** `git clone --branch` only accepts branch/tag names and fails when passed a commit SHA. To shallow fetch a specific commit SHA, initializing a repo with `git init`, setting remote origin, fetching with `git fetch --depth 1 origin <SHA>`, and checking out `FETCH_HEAD` is required.
**Prevention:** Always pin third-party repositories to immutable commit SHAs rather than mutable branch references, and use `git fetch --depth 1 origin <SHA>` + `git checkout FETCH_HEAD` for shallow SHA checkout.
