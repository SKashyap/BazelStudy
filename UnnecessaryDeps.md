# Unnecessary deps 

## How would you identify unnecessary dependencies in the tree? 

#### Define an unnecessary dep :
- Dep that is declared but is not run in any configuration. No path to target. 
- Dep that is getting built as part of all targets, but NOT as part of targets that are actually released in the form of a package. Built but not released. Example : vsm_sdk_zip.
- An external dep which is plugged in but not used anywhere within the workspace. 

#### How to find the internal deps that are unused
- `query` all targets in the workspace that are not a test target and that are not external deps.
  ```
  bazel cquery //tensorflow/... --notool_deps --noimplicit_deps | wc -l
  258
  ```
- `query` all internal targets invoked as part of "released targets"
  ```
  bazel cquery "filter('^//', kind(rule, deps(//tensorflow/tools/lib_package:libtensorflow)))" --notool_deps --noimplicit_deps>../pkgDeps.txt
  ```
- difference between them indicate un-invoked rules. But this might be a wild goose chase. 
- generate a graph of the //... rule and spot these rules and what they feed into.
- Or write a script to find disconnected components and check if they are released

#### More feasible approach 

- `cquery` all targets in the `utils` project that are not a test target and that are not external deps.
  ```
  bazel cquery //tensorflow/core/util --notool_deps --noimplicit_deps | wc -l
  258
  ```
- `cquery` all internal targets invoked as part of "released targets"
  ```
  bazel cquery "filter('^//', kind(rule, deps(//tensorflow/tools/lib_package:libtensorflow)))" --notool_deps --noimplicit_deps>../pkgDeps.txt
  ```
- `cquery` util targets that feeding into the package
  ```
  cat ../pkgDeps.txt| grep "tensorflow/core/util" | wc -l
  72
  ```
- Now repeat over all publicly distributed package targets.
- We boil down to a set of suspects. Now check the path between targets:
```
bazel cquery 'somepath(//tensorflow/tools/lib_package:libtensorflow , //tensorflow/core/util:padding)' --notool_deps --noimplicit_deps --output graph
```

<img width="505" alt="image" src="https://github.com/user-attachments/assets/1db2946c-3a5b-45e9-87f6-6f8a0191ae35" />

I added a dummy rule "//tensorflow/core/util:shwetha" and ran : 
```
bazel cquery 'somepath(//tensorflow/tools/lib_package:libtensorflow , //tensorflow/core/util:shwetha)' --notool_deps --noimplicit_deps --output graph
digraph mygraph {
  node [shape=box];
}
```

#### How to find the external deps that are unused
- same as internal deps
- `query` path from external to release target. OR use rdeps.
- bzl mod has ways to find unused deps. 

## Did you find any in the TensorFlow repository?
