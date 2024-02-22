load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
    "with_feature_set",
)
load(
    "@bazel_arm_toolchains//toolchains:toolchain_info.bzl",
    "ALL_CPU",
    "AVAILABLE_TOOLCHAINS",
)

def find_toolchain(host_arch, host_os, target, version):
    toolchain = None
    for t in AVAILABLE_TOOLCHAINS:
        if all([
            t["host_arch"] == host_arch,
            t["host_os"] == host_os,
            t["target"] == target,
            t["version"] == version,
        ]):
            toolchain = t
            break

    if toolchain == None:
        fail("""
Host architecture, host OS, target, and version combo ({0}, {1}, {2}, {3}) not supported.
If required, file an issue here: https://github.com/agoessling/bazel_arm_toolchains/issues
""".format(host_arch, host_os, target, version))
    return toolchain

def toolchain_deps(host_arch, host_os, target, version):
    toolchain = find_toolchain(host_arch, host_os, target, version)

    TOOLCHAIN_BUILD_FILE = """
filegroup(
    name = "all_files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)"""

    http_archive(
        name = toolchain["name"],
        build_file_content = TOOLCHAIN_BUILD_FILE,
        url = "https://developer.arm.com/-/media/Files/downloads/gnu/{0}/binrel/{1}.tar.xz".format(
            toolchain["version"],
            toolchain["name"],
        ),
        strip_prefix = toolchain["name"],
        sha256 = toolchain["sha256"],
    )

    for cpu in ALL_CPU:
        name_with_cpu = "{}-{}".format(toolchain["name"], cpu)
        native.register_toolchains(
            "@bazel_arm_toolchains//toolchains:{0}_toolchain".format(name_with_cpu),
        )

def all_toolchain_deps():
    for toolchain in AVAILABLE_TOOLCHAINS:
        toolchain_deps(
            toolchain["host_arch"],
            toolchain["host_os"],
            toolchain["target"],
            toolchain["version"],
        )

def toolchain_defs(host_arch, host_os, target, version, cpu):
    toolchain = find_toolchain(host_arch, host_os, target, version)
    name_with_cpu = "{}-{}".format(toolchain["name"], cpu)

    all_files_name = "{0}_all_files".format(toolchain["name"])
    if not native.existing_rule(all_files_name):
        native.filegroup(
            name = all_files_name,
            srcs = [
                "@{0}//:all_files".format(toolchain["name"]),
                "//toolchains:wrappers",
            ],
        )

    cc_arm_toolchain_config(
        name = "{0}_toolchain_config".format(name_with_cpu),
        host_arch = host_arch,
        host_os = host_os,
        target = target,
        version = version,
        cpu = cpu,
    )

    native.cc_toolchain(
        name = "{0}_cc_toolchain".format(name_with_cpu),
        toolchain_config = ":{0}_toolchain_config".format(name_with_cpu),
        all_files = ":{0}".format(all_files_name),
        ar_files = ":{0}".format(all_files_name),
        as_files = ":{0}".format(all_files_name),
        compiler_files = ":{0}".format(all_files_name),
        dwp_files = "//toolchains:empty",
        linker_files = ":{0}".format(all_files_name),
        objcopy_files = "//toolchains:empty",
        strip_files = "//toolchains:empty",
    )

    native.toolchain(
        name = "{0}_toolchain".format(name_with_cpu),
        exec_compatible_with = [
            "@platforms//cpu:{}".format(toolchain["host_arch"]),
            "@platforms//os:{}".format(toolchain["host_os"]),
        ],
        target_compatible_with = [
            "//platforms/cpu:{}".format(cpu),
            "@platforms//os:{}".format(toolchain["target_os"]),
            "//platforms/toolchain_version:{}".format(version),
        ],
        toolchain = "{0}_cc_toolchain".format(name_with_cpu),
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )

def all_toolchain_defs():
    for toolchain in AVAILABLE_TOOLCHAINS:
        for cpu in ALL_CPU:
            toolchain_defs(
                toolchain["host_arch"],
                toolchain["host_os"],
                toolchain["target"],
                toolchain["version"],
                cpu,
            )

def _impl_cc_arm_toolchain_config(ctx):
    """Generic implementation for toolchains provided by Arm.

    Flags and features were crafted to be aligned with the native starlark implementations here:
    https://github.com/bazelbuild/rules_cc/blob/main/cc/private/toolchain/unix_cc_toolchain_config.bzl
    https://github.com/bazelbuild/rules_cc/blob/main/cc/private/toolchain/unix_cc_configure.bzl
    """
    toolchain = find_toolchain(
        ctx.attr.host_arch,
        ctx.attr.host_os,
        ctx.attr.target,
        ctx.attr.version,
    )

    all_compile_actions = [
        ACTION_NAMES.assemble,
        ACTION_NAMES.c_compile,
        ACTION_NAMES.clif_match,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.lto_backend,
        ACTION_NAMES.preprocess_assemble,
    ]

    all_cpp_compile_actions = [
        ACTION_NAMES.clif_match,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.lto_backend,
    ]

    all_link_actions = [
        ACTION_NAMES.cpp_link_executable,
        ACTION_NAMES.cpp_link_dynamic_library,
        ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ]

    tool_paths = []
    for tool, path in toolchain["wrapper_paths"].items():
        tool_paths.append(tool_path(name = tool, path = path))

    feature_compiler_flags = feature(
        name = "compiler_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [flag_group(flags = [
                    "-Wall",
                    "-Wunused-but-set-parameter",
                    "-Wno-free-nonheap-object",
                    "-fdiagnostics-color",
                    "-no-canonical-prefixes",
                    "-fno-canonical-system-headers",
                    "-Wno-builtin-macro-redefined",
                    "-D__DATE__=\"redacted\"",
                    "-D__TIMESTAMP__=\"redacted\"",
                    "-D__TIME__=\"redacted\"",
                ])],
            ),
            flag_set(
                actions = all_cpp_compile_actions,
                flag_groups = [flag_group(flags = [
                    "-std=c++17",
                ])],
            ),
        ],
    )

    feature_linker_flags = feature(
        name = "linker_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [flag_group(flags = [
                    "-Wl,-no-as-needed",
                    "-pass-exit-codes",
                ])],
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [flag_group(flags = [
                    "-Wl,--gc-sections",
                ])],
                with_features = [with_feature_set(features = ["opt"])],
            ),
        ],
    )

    feature_opt = feature(
        name = "opt",
        flag_sets = [flag_set(
            actions = all_compile_actions,
            flag_groups = [flag_group(flags = [
                "-g0",
                "-O2",
                "-DNDEBUG",
                "-ffunction-sections",
                "-fdata-sections",
            ])],
        )],
    )

    feature_dbg = feature(
        name = "dbg",
        flag_sets = [flag_set(
            actions = all_compile_actions,
            flag_groups = [flag_group(flags = [
                "-g",
            ])],
        )],
    )

    feature_cpu = feature(
        name = "cpu",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions + all_link_actions,
                flag_groups = [flag_group(flags = [
                    "-mcpu=" + ctx.attr.cpu,
                ])],
            ),
        ],
    )

    feature_strip_all = feature(
        name = "strip_all",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [flag_group(flags = [
                    "-Wl,--strip-all",
                ])],
            ),
        ]
    )

    features = [
        feature_compiler_flags,
        feature_linker_flags,
        feature_opt,
        feature_dbg,
        feature_cpu,
        feature_strip_all,
    ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        toolchain_identifier = toolchain["name"],
        host_system_name = "local",
        target_system_name = ctx.attr.target,
        target_cpu = ctx.attr.target,
        target_libc = ctx.attr.target,
        compiler = "compiler",
        abi_version = ctx.attr.target,
        abi_libc_version = ctx.attr.target,
        tool_paths = tool_paths,
    )

cc_arm_toolchain_config = rule(
    implementation = _impl_cc_arm_toolchain_config,
    attrs = {
        "host_arch": attr.string(
            mandatory = True,
            doc = "Toolchain host architecture.",
        ),
        "host_os": attr.string(
            mandatory = True,
            doc = "Toolchain host OS.",
        ),
        "target": attr.string(
            mandatory = True,
            doc = "Target toolchain.",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "Toolchain version.",
        ),
        "cpu": attr.string(
            mandatory = True,
            doc = "Target CPU. Passed to gcc as -mcpu=",
        ),
    },
    provides = [CcToolchainConfigInfo],
)
