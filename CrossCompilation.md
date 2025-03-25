# Integrate a cross-compilation toolchain to this project (build for eVocore P8700 cpu)

- Older Bazel : Crosstool and toolchains.
- New Bazel : Platforms and toolchains.
- cross-compile guide for MIPS : https://mipsym.github.io/mipsym/CrossCompile.html

## Steps involved 
- How do you identify a platform? How do you identify a new target platform? Is it a new cpu architecture? New Os? New compiler flags?
- After identification how to make changes to the way you build it. https://mipsym.github.io/mipsym/CrossCompile.html . Is it a new cpu arch? or a new os? These are enumerated in platforms. 
- Create a cc_toolchain_config based on toolchain config changes and propogate what platforms this toochain suite supports. There will be multiple toolchains to support multiple environments. 
- register different flavors of toolchains.
- cc_toolchain becomes the single rule to access any of the flavors and the correct toolchain is choosen at build time based on passed in information about host and target platform. 
- Toolchain per platform? For a Mac system building arm-linux build …what will the toolchain be? Toolchain can get the 
- exec_compatible_With , target_compatible_with. 


## Legacy crosstool way 

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




## New way : Platforms and constraints

1) Defining the Bazel platform .
Existing constraints : 
 cpu : https://github.com/bazelbuild/platforms/blob/main/cpu/BUILD  os: https://github.com/bazelbuild/platforms/blob/main/os/BUILD

Extend by adding new constraints as needed by your new target platform : 
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

2) Defining the C/C++ toolchain config using the constraints
5) Defining the C/C++ toolchain
6) Register toolchain
7) Toolchain resolution based on platforms
