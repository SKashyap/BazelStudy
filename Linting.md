# Integration of static code analysis tools like cppLint

## Requirements
cpplint is a static analysis tool, specifically a linter, for C++ code. It checks for style issues and deviations from Google's C++ style guide. It does not reformat code; instead, it reports violations that need to be manually corrected. Formatters, like clang-format, automatically adjust code layout, while cpplint focuses on identifying style inconsistencies and potential errors.


How static code analysis tools are integrated into bazel and how those targets are built should ideally depend on the usage patterns. 
Ideally I would like to know what the developer steps are : 
- Are devs running linters locally only on the files they touched?
- is the linter run before or after the build? Or alongside.
- is it a pre-commit hook? 
- should linting add to the build time of the targets?
- Or is there a dedicated server build that outputs the entire workspace's lint issues regularly to identify regression? (need for caching and incrementality?)
- Do we want to patch the lint errors or just indicate them as warnings? cppLint does not write. 
- Should linting issues fail the build? Legacy code tends to have many lint issues in older files, so it may cause too many hurdles to build.
- Are we going to cache lint results as part of Bazel's ecosystem?

 In the interest of scoping this talk, I will focus on static code analysis alone. Not formatting. 
  
## Steps to cppLint as an "aspect" (no need to change any rule)

- Create an external dependency on cppLint and register the repository in the project workspace for a hermetic cppLint integration.
- Make cppLint available as a tool within your workspace.
- Add a Tensorflow/tools/cppLint directory within the tensorflow repository. Here include a cpplintaspect.bzl rule which creates an aspect that applies lint to the 
- 

## As validation action inside C++ rules :
https://bazel.build/extending/rules#validation-actions

adds to build time, build error and needs control on the rule. --run_validations

## Steps to integrate cppLint via rules_lint: 
https://registry.bazel.build/modules/aspect_rules_lint

## Steps to integrate as a test
https://github.com/RobotLocomotion/drake/blob/master/tools/lint/cpplint.bzl#L45

https://stackoverflow.com/questions/60091054/configuring-static-analysis-or-linters-for-c-with-bazel

## Steps to integrate linter as a seperate server build 
 bazel build //allFiles:linter  (rule can have a tag: no-linter , or cpp file can have a tag cpplint: Do not lint)

 add a config to to want to lint or not. 

 have a genrule/rule to trigger cpplint on all files within a directory. 
