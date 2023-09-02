#!/bin/bash
set -e
set -o xtrace

bazel clean
bazel build -s --verbose_failures --platforms=//platforms:cortex-m0-none-12.3.rel1 //test:test_cpp
bazel build -s --verbose_failures --platforms=//platforms:cortex-m0-none-12.3.rel1 //test:test_c
bazel build -s --verbose_failures --platforms=//platforms:cortex-m0plus-none-12.3.rel1 //test:test_cpp
bazel build -s --verbose_failures --platforms=//platforms:cortex-m0plus-none-12.3.rel1 //test:test_c
bazel build -s --verbose_failures --platforms=//platforms:cortex-m1-none-12.3.rel1 //test:test_cpp
bazel build -s --verbose_failures --platforms=//platforms:cortex-m1-none-12.3.rel1 //test:test_c
bazel build -s --verbose_failures --platforms=//platforms:cortex-m3-none-12.3.rel1 //test:test_cpp
bazel build -s --verbose_failures --platforms=//platforms:cortex-m3-none-12.3.rel1 //test:test_c
bazel build -s --verbose_failures --platforms=//platforms:cortex-m4-none-12.3.rel1 //test:test_cpp
bazel build -s --verbose_failures --platforms=//platforms:cortex-m4-none-12.3.rel1 //test:test_c
bazel build -s --verbose_failures --platforms=//platforms:cortex-m7-none-12.3.rel1 //test:test_cpp
bazel build -s --verbose_failures --platforms=//platforms:cortex-m7-none-12.3.rel1 //test:test_c
bazel build -s --verbose_failures --platforms=//platforms:cortex-m7+nofp.dp-none-12.3.rel1 //test:test_cpp
bazel build -s --verbose_failures --platforms=//platforms:cortex-m7+nofp.dp-none-12.3.rel1 //test:test_c
bazel build -s --verbose_failures --platforms=//platforms:cortex-a8-none-12.3.rel1 //test:test_cpp
bazel build -s --verbose_failures --platforms=//platforms:cortex-a8-none-12.3.rel1 //test:test_c
bazel build -s --verbose_failures --platforms=//platforms:cortex-a9-none-12.3.rel1 //test:test_cpp
bazel build -s --verbose_failures --platforms=//platforms:cortex-a9-none-12.3.rel1 //test:test_c
