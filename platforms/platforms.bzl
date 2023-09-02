load("@bazel_arm_toolchains//toolchains:toolchain_info.bzl", "ALL_CPU", "AVAILABLE_TOOLCHAINS")

def all_platforms():
    for toolchain in AVAILABLE_TOOLCHAINS:
        for cpu in ALL_CPU:
            name = "{}-{}-{}".format(cpu, toolchain["target_os"], toolchain["version"])
            native.platform(
                name = name,
                constraint_values = [
                    "//platforms/cpu:{}".format(cpu),
                    "@platforms//os:{}".format(toolchain["target_os"]),
                    "//platforms/toolchain_version:{}".format(toolchain["version"]),
                ],
                visibility = ["//visibility:public"],
            )
