# Unnecessary deps 

## How would you identify unnecessary dependencies in the tree? 

#### Define an unnecessary dep :
- Dep that is declared but is not run in any configuration. No path to target. 
- Dep that is getting built as part of all targets, but NOT as part of targets that are actually released in the form of a package. Built but not released. Example : vsm_sdk_zip.
- An external dep which is plugged in but not used anywhere within the workspace. 

#### How to find the internal deps that are unused
- `query` all targets in the workspace that are not a test target and that are not external deps.
- `query` all targets invoked as part of "released targets"
- difference between them indicate un-invoked rules.
- generate a graph of the //... rule and spot these rules and what they feed into.
- Or write a script to find disconnected components and check if they are released

#### How to find the external deps that are unused
- same as internal deps
- `query` path from external to release target. OR use rdeps.
- bzl mod has ways to find unused deps. 

## Did you find any in the tensorflow repository?
