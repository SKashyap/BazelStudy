## Integration of static code analysis tools
How static code analysis tools are integrated into bazel and how those targets are built should ideally depend on the usage patterns. 
Ideally I would like to know how the developer steps are : 
- Are devs running linters locally only on the files they touched?
- is linter run before or after the build? Or alongside.
- is it a pre-commit hook?
- Or is there a dedicated server build which outputs the entire workspace's lint issues regulary to identify regerssion?
- Do we want to path the lint errors or just indicate them as warnings?
- Should linting issues fail the build? Legacy code tends to have many lint issues in older files, so it may cause too many hurdles to build.
- Are going to cache lint results as part of bazel's ecosystem?
  

# Steps to cppLint as an "aspect"

- Create an external depenedency on cppLint and register the respository in the project workspace for a hermetic cppLint integration.
- Add a Tensorflow/tools/cppLint directory within the tensorflow repository. Here include a cpplintaspect.bzl rule which creates an aspect that applies lint to the 
- 


# Steps to integrate cppLint via rules_lint: 

# Steps to integrate linter as a seperate server build 
 bazel build //allFiles:linter  (rule can have a tag: no-linter , or cpp file can have a tag cpplint: Do not lint)

 add a config to to want to lint or not. 

 have a genrule/rule to trigger cpplint on all files within a directory. 
# Steps to integrate as a test
