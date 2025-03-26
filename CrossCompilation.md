# Integrate a cross-compilation toolchain to this project (build for eVocore P8700 cpu)

- Older Bazel : Crosstool-top.
- New Bazel : Platforms and contraints.

## Steps involved 
- How do you identify a platform? How do you identify a new target platform? Is it a new cpu architecture? New Os? New compiler flags? These are enumerated in `platforms`. 
- After identification how to make changes to the way you build it? 
- Create a cc_toolchain_config based on toolchain config changes and propagate what platforms this toolchain suite supports. There will be multiple toolchains to support multiple environments. 
- Register different flavors of toolchains.
- cc_toolchain becomes the single rule to access any of the flavors, and the correct toolchain is chosen at build time based on the passed in information about the host and target platform. 

## New way : Platforms and constraints 

1) Defining the Bazel platform.
Existing constraints : 
 cpu : https://github.com/bazelbuild/platforms/blob/main/cpu/BUILD  os: https://github.com/bazelbuild/platforms/blob/main/os/BUILD

Extend by adding new constraints as needed by your new target platform. Here I have chosen a random platform for example. 
```
constraint_value(
    name = "riscv64",
    constraint_setting = "@platforms//cpu:cpu",
)

platform(
    name = "my_new_platform",
    constraint_values = [
        ":riscv64",
    ],
)
```

2) Defining the C/C++ toolchain config using the constraints, features etc
   
```
rv64_bare_metal_toolchain_config = rule(
  implementation = _impl,
  attrs = {},
  provides = [CcToolchainConfigInfo],
)

  ```
3) Defining the C/C++ toolchain and mark with target_compatible_with , exec_compatible_with attribute to bind them to a platform.
   ```
   toolchain(
      name = "riscv64_bare_metal_toolchain_from_linux_x86_64",
      exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
      ],
      target_compatible_with = [
        "//platform:bare_metal",
        "@platforms//cpu:riscv64",
      ],
      toolchain = ":rv64_bare_metal_toolchain",
      toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
   )
   ```
5) Register toolchain
6) Toolchain resolution based on platforms

## Legacy crosstool way 

//Tensoflow/BUILD has all the contraints. 
//tensorflow/tools/toolchains/BUILD has platforms

#### Toolchain creation :
```
cc_toolchain(
    name = "linux_aarch64_toolchain",
    all_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 1,
    toolchain_config = ":linux_aarch64_toolchain_config",
    toolchain_identifier = "linux_aarch64_toolchain",
)

cc_toolchain_config(
    name = "linux_aarch64_toolchain_config",
    abi_libc_version = "local",
    abi_version = "local",
    builtin_sysroot = "/dt10/",
    compile_flags = [
        "--target=aarch64-unknown-linux-gnu",
        "-fstack-protector",
        "-Wall",
        "-Wthread-safety",
        "-Wself-assign",
        "-Wunused-but-set-parameter",
        "-Wno-free-nonheap-object",
        "-fcolor-diagnostics",
        "-fno-omit-frame-pointer",
        "-mtune=generic",
        "-march=armv8-a",
    ],
    compiler = "clang",
    coverage_compile_flags = ["--coverage"],
    coverage_link_flags = ["--coverage"],
    cpu = "aarch64",
    cxx_builtin_include_directories = [
        "/dt10/",
        "/usr/lib/llvm-18/include/",
        "/usr/lib/llvm-18/lib/clang/18/include",
    ],
    dbg_compile_flags = ["-g"],
    host_system_name = "linux",
    link_flags = [
        "--target=aarch64-unknown-linux-gnu",
        "-fuse-ld=lld",
        "--ld-path=/usr/lib/llvm-18/bin/ld.lld",
        "-Wl,--undefined-version",
    ],
    link_libs = [
        "-lstdc++",
        "-lm",
    ],
    opt_compile_flags = [
        "-g0",
        "-O2",
        "-D_FORTIFY_SOURCE=1",
        "-DNDEBUG",
        "-ffunction-sections",
        "-fdata-sections",
    ],
    opt_link_flags = ["-Wl,--gc-sections"],
    supports_start_end_lib = True,
    target_libc = "",
    target_system_name = "aarch64-unknown-linux-gnu",
    tool_paths = {
        "gcc": "/usr/lib/llvm-18/bin/clang",
        "ld": "/usr/lib/llvm-18/bin/ld.lld",
        "ar": "/usr/lib/llvm-18/bin/llvm-ar",
        "cpp": "/usr/lib/llvm-18/bin/clang++",
        "llvm-cov": "/usr/lib/llvm-18/bin/llvm-cov",
        "nm": "/usr/lib/llvm-18/bin/llvm-nm",
        "objdump": "/usr/lib/llvm-18/bin/llvm-objdump",
        "strip": "/usr/lib/llvm-18/bin/llvm-strip",
    },
    toolchain_identifier = "linux_aarch64_toolchain",
    unfiltered_compile_flags = [
        "-no-canonical-prefixes",
        "-Wno-builtin-macro-redefined",
        "-D__DATE__=\"redacted\"",
        "-D__TIMESTAMP__=\"redacted\"",
        "-D__TIME__=\"redacted\"",
        "-Wno-unused-command-line-argument",
        "-Wno-gnu-offsetof-extensions",
    ],
)

cc_toolchain_suite(
    name = "cross_compile_toolchain_suite",
    toolchains = {
        "aarch64": ":linux_aarch64_toolchain",
    },
)
```
#### The toolchain selection

1) User specifies a `cc_toolchain_suite` target in the BUILD file and points Bazel to the target using the --crosstool_top option.

.bazelrc
```
build:cross_compile_linux_arm64 --crosstool_top=//tensorflow/tools/toolchains/cross_compile/cc:cross_compile_toolchain_suite
build:cross_compile_macos_x86 --crosstool_top=//tensorflow/tools/toolchains/cross_compile/cc:cross_compile_toolchain_suite
```

3) The cc_toolchain_suite target references multiple toolchains. The values of the --cpu and --compiler flags determine which of those toolchains is selected based only on the --cpu flag value or a joint --cpu | --compiler value. The selection process is as follows:
```
cc_toolchain_suite(
    name = "cross_compile_toolchain_suite",
    toolchains = {
        "aarch64": ":linux_aarch64_toolchain",
        "k8": ":linux_x86_toolchain",
        "darwin": ":macos_x86_toolchain",
    },
)
```






## Changes to the project rules based on the newly added platform
- Avoid rules from getting executed on the new platform with `target_compatible_with` flag
  ```
    #bazel build -s --platforms=//platform:riscv64_bare_metal //program
    cc_binary(
      name = "program",
      srcs = [
        "program.c",
        "boot.S",
      ],
      additional_linker_inputs = [
        "link_script.ld",
      ],
      linkopts = ["-Wl,-T $(location :link_script.ld)"],
      target_compatible_with = BARE_METAL_RISCV64_CONSTRAINTS,
    )
  ```
- Create `universal binary` rule which `selects` the correct binary based on platforms.  Example Crypto.
  <img width="609" alt="4 - Use platform information to pick dependencies" src="https://github.com/user-attachments/assets/21173bce-b938-4ea3-b78a-f4f44f103188" />

