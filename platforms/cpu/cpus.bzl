load("@bazel_arm_toolchains//toolchains:toolchain_info.bzl", "ALL_CPU")

def all_cpus():
    for cpu in ALL_CPU:
        native.constraint_value(
            name = cpu,
            constraint_setting = "//platforms/cpu:cpu",
            visibility = ["//visibility:public"],
        )
