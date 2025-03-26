# Unnecessary deps 

## How would you identify unnecessary dependencies in the tree? 

#### Define an unnecessary dep :
- Dep that is declared but is not run in any configuration. No path to target. 
- Dep that is getting built as part of all targets, but NOT as part of targets that are actually released in the form of a package. Built but not released. 
- An external dep that is plugged in but not used anywhere within the workspace. 

#### How to find the internal deps that are unused

##### The top-level graph approach (only for small projects)
- `query` for `all targets in the workspace` that are not a test target and that are not external deps. This is not possible in tensorflow, coz we can't build //tensorflow/...
  ```
  bazel cquery "deps(//...)" --notool_deps --noimplicit_deps --output graph| wc -l
  ```
  In a small project, this graph can be seen visually to find disconnected components and analyze if they are release targets or not.
  Graphviz also provides API to work on a digraph and count the components.
- For tensorFlow repository, "//..." does not even build! So, we cannot attempt this.


##### More feasible approach - start with a small directory to examine if it feeds all of its targets into a published package

- `cquery` all targets in the `tensorflow/core/utils` project that are not a test target and that are not external deps.
  ```
  bazel cquery //tensorflow/core/util --notool_deps --noimplicit_deps | wc -l
  258
  ```
- `cquery` all internal targets invoked as part of "released targets" like `libtensorflow`
  ```
  bazel cquery "filter('^//', kind(rule, deps(//tensorflow/tools/lib_package:libtensorflow)))" --notool_deps --noimplicit_deps>../pkgDeps.txt
  ```
- `cquery` core/util targets that feed into the above package
  ```
  cat ../pkgDeps.txt| grep "tensorflow/core/util" | wc -l
  72
  ```
- Now repeat over all publicly distributed package targets. We should see all 258 targets within `util` feed into something. Bazel query has `union`, `intersect` operations to work on these sets.
- After the above steps, we would have come down to a set of suspects. Now check the path between the suspect and the package to verify:
```
bazel cquery 'somepath(//tensorflow/tools/lib_package:libtensorflow , //tensorflow/core/util:padding)' --notool_deps --noimplicit_deps --output graph
```

<img width="505" alt="image" src="https://github.com/user-attachments/assets/1db2946c-3a5b-45e9-87f6-6f8a0191ae35" />

I added a dummy rule that does not feed any package "//tensorflow/core/util:shwetha" and ran : 
```
bazel cquery 'somepath(//tensorflow/tools/lib_package:libtensorflow , //tensorflow/core/util:shwetha)' --notool_deps --noimplicit_deps --output graph
digraph mygraph {
  node [shape=box];
}
```

#### How to find the external deps that are unused
- same as internal deps
- bzl-mod has ways to find unused deps. 

## Did you find any in the TensorFlow repository?
It/s too big a WORKSPACE to focus on. If I am given a scoped-down problem, I can check. 
