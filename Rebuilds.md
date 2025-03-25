# Rebuilds

The development team has reported that even when they are not changing the code, at
times some targets get rebuilt. What would be your approach to resolve this issue?

## Approach to solve. 

1) Collect logs for the rebuilt binaries. ( -s command) . Comared two logs and spot the changing parameter.
2) Look out for Bazel logs providing a warning about cache invalidation. 
3) Typically config parameters provided on command line lead to confusion when developers run the builds. Add short alias to to configs and embed them in .bazelrc to avoid cache invalidation.
4) Figure out at what stage the invalidation occurred. 
5) The execution log can help you to troubleshoot and fix missing remote cache hits due to machine and environment differences or non-deterministic actions
6) if the problem came because of non-hermeticity issues as mentioned in hermiticity.md file, then fix those issues. If they cannot be fixed, exclude them from caching. 
7) Dump the actioncache key and check for changes. 

```
WARNING: Build options --check_visibility and --macos_sdk_version have changed, discarding analysis cache (this can be expensive, see https://bazel.build/advanced/performance/iteration-speed).
```
