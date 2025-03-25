# Rebuilds

The development team has reported that even when they are not changing the code, at
times some targets get rebuilt. What would be your approach to resolve this issue?

## Approach to solve. 

1) Collect logs for the rebuilt binaries. ( -s command) . Comared two logs and spot the changing parameter. Action-key = Hash(commands)
2) Look out for Bazel logs providing a warning about cache invalidation. 
3) Typically config parameters provided on command line lead to confusion when developers run the builds. Add short alias to to configs and embed them in .bazelrc to avoid cache invalidation.
4) Figure out at what stage the invalidation occurred. 
5) The execution log can help you to troubleshoot and fix missing remote cache hits due to machine and environment differences or non-deterministic actions
6) if the problem came because of non-hermeticity issues as mentioned in hermiticity.md file, then fix those issues. If they cannot be fixed, exclude them from caching. 
7) Dump the actioncache key and check for changes. 

```
WARNING: Build options --check_visibility and --macos_sdk_version have changed, discarding analysis cache (this can be expensive, see https://bazel.build/advanced/performance/iteration-speed).
```

```
See execution_log locally
```

```
33572, bazel-out/darwin_arm64-opt/bin/tensorflow/cpplint.runfiles_manifest:
      actionKey = 8822f49f63e83957e5e488aa567980c65b8aa222f391cff83faf556f8dd43217
      usedClientEnvKey = 
      digestKey = 9cbb01fb0136efe3be675d27131903bab7a92e6066633d770a43926e89553bb2

      packed_len = 106

33573, bazel-out/darwin_arm64-opt/bin/tensorflow/cpplint.runfiles/MANIFEST:
      actionKey = 006ad32cf31ae6da7921fa515c365cbb1c2d1b461bb50eb358605877a5af45a0
      usedClientEnvKey = 8f8c35f4d49093b1a8656b101c8ac2b71d34a66b969a774349051d4dcb0f7e03
      digestKey = b874ead1f9037b57ce4cba3ae0745ed75318849095cdab9d1e97be37ee5b0e34

      packed_len = 138

33574, bazel-out/darwin_arm64-opt/internal/_middlemen/tensorflow_Scpplint-runfiles:
      actionKey = 
      usedClientEnvKey = 
      digestKey = 69dec2da192583ca4d708d093a70ae0147ecf17aa80d0910f95c7fa259e4418c

      packed_len = 42
```

