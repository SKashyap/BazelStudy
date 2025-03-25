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

 ![image](https://github.com/user-attachments/assets/eba6a737-45f2-4e8b-b6d9-0e3b0327899e)

  
## Steps to cppLint as an "aspect" (no need to change any rule)

![image](https://github.com/user-attachments/assets/093849f5-dbc2-4cac-a8dc-ef90f0663945)

![image](https://github.com/user-attachments/assets/f71ff970-6fd9-45e4-aedb-05f8b3e90817)

## My POC with non-hermetic cppunit

Command:
```
bazel build //tensorflow/core/util:padding --macos_sdk_version=15.2 --aspects //tensorflow/core/util:cppLint_aspect.bzl%linter --output_groups=report
```

Output : 
![image](https://github.com/user-attachments/assets/2d3125e0-0c0f-421c-9d39-6a7143ff8bbe)

Contents of the generate lint text file : 
![image](https://github.com/user-attachments/assets/700b9e44-a8b1-4eda-bda6-d7f552787378)

## How to formally integrate
- Create a tensorflow/third-party directory for cppLint.
- Add a WORKSPACE file with rules to fetch cpplint from github / bzlmod for hermeticity.
  ```
  # //:WORKSPACE
  bazel_dep(name = "cpplint", version = "2.0.0")
  ```
- Add a py_binary rule to capture the script :
  ```
  py_binary(
    name = "cpplint",
    srcs = ["cpplint.py"],
  )
  ```
- Add an aspect definition on the lines `linter.bzl` of that uses cpp_lint as a hermetic tool or executable . Convert run_shell ro run() call. 
- Register the repository in the project workspace for a hermetic cppLint integration.
- Make `linter` aspect available to the tensorflow by add this external depenedency as "repository" -> @cppLint
- Now rules within testflow can invoke it as follows :

  ```
   bazel build //... \
  --aspects @bazel_cppLint//cppLint_aspect.bzl%linter \
  --output_groups=report \
  ```
  
## As validation action inside C++ rules :
https://bazel.build/extending/rules#validation-actions

adds to build time, build error and needs control on the rule. --run_validations

## Steps to integrate cppLint via rules_lint: 
https://registry.bazel.build/modules/aspect_rules_lint

## Steps to integrate as a test

```
py_test(
    name = "solution_cpplint_test",
    srcs = ["@cpplint_archive//:cpplint"],
    args = ["solution/%s" % f for f in glob([
        "**/*.cc",
        "**/*.h",
    ])],
    data = [":solution_filegroup"],
    main = "cpplint.py",
)
```
https://github.com/RobotLocomotion/drake/blob/master/tools/lint/cpplint.bzl#L45


## Steps to integrate linter as a separate server build 
 bazel build //allFiles:linter  (rule can have a tag: no-linter , or cpp file can have a tag cpplint: Do not lint)

 add a config to want to lint or not. 

 have a genrule/rule to trigger cpplint on all files within a directory. 
