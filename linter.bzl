"""
POC for an Aspect to run a linter using the system cpplint (non-hermetic).

Command to run:
bazel build //tensorflow/core/util:padding --verbose_failures --macos_sdk_version=15.2 --check_visibility=false --aspects //tensorflow/core/util:cppLint_aspect.bzl%linter --output_groups=report
"""

def cppLint_file(file, ctx):
    print(file.path)
    outfile = ctx.actions.declare_file("cppLint_" + file.basename + ".txt")
    print(outfile.path)

    ctx.actions.run_shell(outputs =[outfile], 
                        inputs = [file], 
                        use_default_shell_env = True,
                        progress_message = "Running CPPLint on %s"%file, 
                        command = "(cpplint --filter=-whitespace %s &> %s)"%(file.path, outfile.path))

    return outfile

def rule_sources(attr):
    header_extensions = (
        ".h",
        ".hh",
        ".hpp",
        ".hxx",
        ".inc",
        ".inl",
        ".H",
    )
    permitted_file_types = [
        ".c",
        ".cc",
        ".cpp",
        ".cxx",
        ".c++",
        ".C",
    ] + list(header_extensions)
    def check_valid_file_type(src):
        """
        Returns True if the file type matches one of the permitted srcs file types for C and C++ header/source files.
        """
        for file_type in permitted_file_types:
            if src.basename.endswith(file_type):
                return True
        return False

    srcs = []
    if hasattr(attr, "srcs"):
        for src in attr.srcs:
            srcs += [src for src in src.files.to_list() if src.is_source and check_valid_file_type(src)]
    if hasattr(attr, "hdrs"):
        for hdr in attr.hdrs:
            srcs += [hdr for hdr in hdr.files.to_list() if hdr.is_source and check_valid_file_type(hdr)]
    return srcs


def _linter_impl(target, ctx):
    print("shwetha aspect")
    print("Visiting %s" % target.label)

    if not CcInfo in target:
        print("not calling for non cc targets")
        return [OutputGroupInfo(report = depset([]))]

    if target.label.workspace_root.startswith("external"):
        print("not calling for external targets")
        return [OutputGroupInfo(report = depset([]))] 
            
    srcs = rule_sources(ctx.rule.attr)
    outputs = []
    for file in srcs:
        outputs.append(cppLint_file(file, ctx))
    print("--------------")
    print(len(outputs))

    return [OutputGroupInfo(report = depset(outputs))]


linter = aspect(
    implementation = _linter_impl,
    attr_aspects = ["implementation-deps"], # no transitive deps
)
