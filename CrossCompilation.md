# Integrate a cross-compilation toolchain to this project (build for eVocore P8700 cpu)

Older Bazel : Crosstool and toolchains
New Bazel : Platforms and toolchains. 

## Steps involved 
- How do you identify a platform? How do you identify a new target platform? How do you identify a new host platform? Our case is a target platform. 
- After identification how to make changes to the way you build it. Is it a new cpu arch? or a new os? These are enumerated in platforms. 
- Create a cc_toolchain_suite based on toolchain config and propogate what platforms this toochain suite supports. There will be multiple toolchain_suite to support multiple environments. 
- register different flavors of toolchain suites.
- cc_toolchain becomes the signle rule to access any of the flavors and the correct toolchain is choosen at build time based on passed in information about host and target platform. 
- Toolchain per platform? For a Mac system building arm-linux build …what will the toolchain be? Toolchain can get the 
- exec_compatible_With , target_compatible_with. 
