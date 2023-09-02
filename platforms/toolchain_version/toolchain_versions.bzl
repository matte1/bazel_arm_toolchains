load("@bazel_arm_toolchains//toolchains:toolchain_info.bzl", "AVAILABLE_TOOLCHAINS")

def all_toolchain_versions():
    for toolchain in AVAILABLE_TOOLCHAINS:
        if not native.existing_rule(toolchain["version"]):
            native.constraint_value(
                name = toolchain["version"],
                constraint_setting = "//platforms/toolchain_version:toolchain_version",
                visibility = ["//visibility:public"],
            )
