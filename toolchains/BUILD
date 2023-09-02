load("@bazel_arm_toolchains//toolchains:toolchains.bzl", "all_toolchain_defs")

filegroup(name = "empty")

filegroup(
    name = "wrappers",
    srcs = glob(["tool_wrappers/**"]),
)

all_toolchain_defs()
