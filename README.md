# bazel_arm_toolchains

Provides hermetic [Bazel](https://bazel.build/) C/C++ toolchains from
[ARM](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads).

## Usage

### WORKSPACE

To incorporate `bazel_arm_toolchains` toolchains into your project, copy the following into your
`WORKSPACE` file.

```Starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_arm_toolchains",
    # See release page for latest version url and sha.
)

load("@bazel_arm_toolchains//toolchains:toolchains.bzl", "all_toolchain_deps")

all_toolchain_deps()
```

This will bring all of the available toolchains (and their associated
[`platform`](https://bazel.build/docs/platforms) definitions) into your project.  The toolchains will
only be downloaded when actually utilized, but if you prefer, you can only import a specific
toolchain:

```Starlark
load("@bazel_arm_toolchains//toolchains:toolchains.bzl", "toolchain_deps")

toolchain_deps(
    host_arch = "x86_64",
    host_os = "linux",
    target = "arm-none-eabi",
    version = "12.3.rel1",
)
```

`host_arch`, `host_os`, `target`, and `version` should match the naming convention of the
[ARM](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads) pre-built toolchains.

NOTE: The `linux` host OS is omitted from the ARM toolchain name.

### Available Toolchains and CPUs

Currently `bazel_arm_toolchains` provides the following toolchains:

| Host Architecture | Host OS | Target | Version |
| --- | --- | --- | --- |
| `x86_64` | `linux` | `arm-none-eabi` | `12.3.rel1` |

and the following CPUs:

| CPU |
| --- |
| `cortex-m0` |
| `cortex-m0plus` |
| `cortex-m1` |
| `cortex-m3` |
| `cortex-m4` |
| `cortex-m7` |
| `cortex-m7+nofp.dp` |
| `cortex-a8` |
| `cortex-a9` |

Available options match the `-mpu=`
[GCC](https://gcc.gnu.org/onlinedocs/gcc/ARM-Options.html#index-mcpu-2) flags.

These lists are easily expanded.  If a toolchain or CPU of interest isn't available feel free to
submit and [issue](https://github.com/agoessling/bazel_bootlin/issues), or alternatively take a look
at `_AVAILABLE_TOOLCHAINS` in [`setup_toolchains.py`](setup_toolchains.py) and create a pull
request. Don't forget to actually run `setup_toolchains.py` after adding a toolchain and before
submitting a PR:

```Shell
bazel run //:setup_toolchains
```

### Platforms

`bazel_arm_toolchains` defines a different [`platform`](https://bazel.build/docs/platforms) for each
toolchain, CPU combo:

```Starlark
native.platform(
    name = {cpu}-{target_os}-{version},
    constraint_values = [
        "//platforms/cpu:{cpu}",
        "@platforms//os:{target_os}",
        "//platforms/toolchain_version:{version}",
    ],
    visibility = ["//visibility:public"],
)
```

To see all available platforms run:

```Shell
bazel query @bazel_arm_toolchains//platforms:*
```

### Building With Toolchain

In order to enable toolchain selection via platforms, Bazel requires a special flag along with the
target platform:

```Shell
bazel build --incompatible_enable_cc_toolchain_resolution --platforms=@bazel_arm_toolchains//platforms:{cpu}-{target_os}-{version} //...
```

The host architecture and OS will be derived automatically and the correct toolchain used.

The ergonomics can be improved by placing the flags in a
[`.bazelrc`](https://bazel.build/docs/bazelrc) file:

```Shell
build --incompatible_enable_cc_toolchain_resolution
build --platforms=@bazel_arm_toolchains//platforms:{cpu}-{target_os}-{version}
```

Then a simple `bazel build //...` will utilize the desired toolchain.
