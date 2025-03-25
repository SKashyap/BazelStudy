# Hermeticity
A build is hermetic if it is not affected by the details of the environment where it is performed. 

## How would you verify that the build is hermetic?

Here are the different approaches to fish for hermeticity issues :  
1) Diff the execution logs between minor changes to the environment. 
2) Use Bazel's "WorkspaceEvents" log to look for rules that reach and grab details from the host system. Events flagged as suspects :
   ```
    ExecuteEvent execute_event = 3;
    DownloadEvent download_event = 4;
    DownloadAndExtractEvent download_and_extract_event = 5;
    FileEvent file_event = 6;
    OsEvent os_event = 7;
    SymlinkEvent symlink_event = 8;
    TemplateEvent template_event = 9;
    WhichEvent which_event = 10;
    ExtractEvent extract_event = 11;
    ReadEvent read_event = 12;
    DeleteEvent delete_event = 13;
    PatchEvent patch_event = 14;
    RenameEvent rename_event = 15;
   ```

Ref: `--experimental_workspace_rules_log_file` => https://docs.bazel.build/versions/master/workspace-log.html

3) Code review for common patterns of known hermetic issues. For example, in C++ projects, the linkOpts may refer to sharedLibs from the host systems.
4) Getting external dependencies via bzlMod or ensuring they are pinned to a certain SHA-id is a good way to verify external library dependencies. (show example of hermetic python, and others with pinned SHA-ID)

```
 Example:  all `download_and_extract_event` in this project is hermetic since sha256(version) is pinned

> grep -B2 -A5 "download_and_extract_event" ../hemerticiyTest.txt | grep sha256 | wc -l
      60
> grep "download_and_extract_event" ../hemerticiyTest.txt | wc -l
      60
```

## Is there any hermeticity issue or limitation with this project?

1) Non-hermetic toolchain : xcode-clang usage

Symptom seen : tensorflow c++ targets `//tensorflow/core` cannot be readily built on macos when xcode(and clang) is not installed. After installing xcode, the local xcode config is read and then the compilation occurs. This is unlike Hermetic CUDA or Hermetic Python which never relies on host-system configurations. 

In the logs, we can see this being highlighted under "execute_event" :

```  
location: "/private/var/tmp/_bazel_shwetha/62e3ac13802c5ff72c884d3c0fc01001/external/bazel_tools/tools/osx/xcode_configure.bzl:165:50"
context: "repository @@local_config_xcode"
execute_event {
  arguments: "./xcode-locator-bin"
  arguments: "-v"
  timeout_seconds: 600
  environment {
  }
  quiet: true
  output_directory: "/private/var/tmp/_bazel_shwetha/62e3ac13802c5ff72c884d3c0fc01001/external/local_config_xcode"
}
```

Source : https://github.com/bazelbuild/bazel/blob/master/tools/osx/xcode_configure.bzl

```
def run_xcode_locator(repository_ctx, xcode_locator_src_label):
    """Generates xcode-locator from source and runs it.

    Builds xcode-locator in the current repository directory.
    Returns the standard output of running xcode-locator with -v, which will
    return information about locally installed Xcode toolchains and the versions
    they are associated with.

    This should only be invoked on a darwin OS, as xcode-locator cannot be built
    otherwise.

    Args:
      repository_ctx: The repository context.
      xcode_locator_src_label: The label of the source file for xcode-locator.
    Returns:
      A 2-tuple containing:
      output: A list representing installed xcode toolchain information. Each
          element of the list is a struct containing information for one installed
          toolchain. This is an empty list if there was an error building or
          running xcode-locator.
      err: An error string describing the error that occurred when attempting
          to build and run xcode-locator, or None if the run was successful.
    """
    repository_ctx.report_progress("Building xcode-locator")
    xcodeloc_src_path = str(repository_ctx.path(xcode_locator_src_label))
    env = repository_ctx.os.environ
    if "BAZEL_OSX_EXECUTE_TIMEOUT" in env:
        timeout = int(env["BAZEL_OSX_EXECUTE_TIMEOUT"])
    else:
        timeout = OSX_EXECUTE_TIMEOUT

    xcrun_result = repository_ctx.execute([
        "env",
        "-i",
        "DEVELOPER_DIR={}".format(env.get("DEVELOPER_DIR", default = "")),
        "xcrun",
        "--sdk",
        "macosx",
        "clang",
        "-mmacosx-version-min=10.13",
        "-fobjc-arc",
        "-framework",
        "CoreServices",
        "-framework",
        "Foundation",
        "-o",
        "xcode-locator-bin",
        xcodeloc_src_path,
    ], timeout)

    if (xcrun_result.return_code != 0):
        suggestion = ""
        if "Agreeing to the Xcode/iOS license" in xcrun_result.stderr:
            suggestion = ("(You may need to sign the Xcode license." +
                          " Try running 'sudo xcodebuild -license')")
        error_msg = (
            "Generating xcode-locator-bin failed. {suggestion} " +
            "return code {code}, stderr: {err}, stdout: {out}"
        ).format(
            suggestion = suggestion,
            code = xcrun_result.return_code,
            err = xcrun_result.stderr,
            out = xcrun_result.stdout,
        )
        return ([], error_msg.replace("\n", " "))

    repository_ctx.report_progress("Running xcode-locator")
    xcode_locator_result = repository_ctx.execute(
        ["./xcode-locator-bin", "-v"],
        timeout,
    )
    if (xcode_locator_result.return_code != 0):
        error_msg = (
            "Invoking xcode-locator failed, " +
            "return code {code}, stderr: {err}, stdout: {out}"
        ).format(
            code = xcode_locator_result.return_code,
            err = xcode_locator_result.stderr,
            out = xcode_locator_result.stdout,
        )
        return ([], error_msg.replace("\n", " "))
    xcode_toolchains = []

    # xcode_dump is comprised of newlines with different installed Xcode versions,
    # each line of the form <version>:<comma_separated_aliases>:<developer_dir>.
    xcode_dump = xcode_locator_result.stdout
    for xcodeversion in xcode_dump.split("\n"):
        if ":" in xcodeversion:
            infosplit = xcodeversion.split(":")
            toolchain = struct(
                version = infosplit[0],
                aliases = infosplit[1].split(","),
                developer_dir = infosplit[2],
            )
            xcode_toolchains.append(toolchain)
    return (xcode_toolchains, None)
```


2) Although Tensorflow uses hermetic python, there may be external trasitive deps that do not use hermetic python. Like this one here using `which python3 , which python` to run a command  :
```
   location: "/private/var/tmp/_bazel_shwetha/62e3ac13802c5ff72c884d3c0fc01001/external/llvm-raw/utils/bazel/configure.bzl:39:38"
context: "repository @@llvm-project"
which_event {
  program: "python3"
}
```

3) shared library reference via likopts in third-party system lib deps  :

```
./third_party/xla/third_party/systemlibs/boringssl.BUILD
cc_library(
    name = "ssl",
    linkopts = ["-lssl"],
    visibility = ["//visibility:public"],
    deps = [
        ":crypto",
    ],
)
```

```
./third_party/flatbuffers/BUILD.system
# Public flatc compiler library.
cc_library(
    name = "flatc_library",
    linkopts = ["-lflatbuffers"],
    visibility = ["//visibility:public"],
)

genrule(
    name = "lnflatc",
    outs = ["flatc.bin"],
    cmd = "ln -s $$(which flatc) $@",
)
```



