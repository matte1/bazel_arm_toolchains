import argparse
import os

_AVAILABLE_TOOLCHAINS = [
    {
        'host_arch': 'x86_64',
        'host_os': 'linux',
        'target': 'arm-none-eabi',
        'version': '12.3.rel1',
        'sha256': '12a2815644318ebcceaf84beabb665d0924b6e79e21048452c5331a56332b309',
    },
]

# GCC cpu options: https://gcc.gnu.org/onlinedocs/gcc/ARM-Options.html#index-mcpu-2
_ALL_CPU = [
    'cortex-m0',
    'cortex-m0plus',
    'cortex-m1',
    'cortex-m3',
    'cortex-m4',
    'cortex-m7',
    'cortex-m7+nofp.dp',
    'cortex-a8',
    'cortex-a9',
]

_ALL_TOOLS = ['ar', 'as', 'cpp', 'gcc', 'gcov', 'ld', 'nm', 'objcopy', 'objdump', 'strip']


def create_wrappers(toolchain_dir):
  for toolchain in _AVAILABLE_TOOLCHAINS:
    host_os_name = '' if toolchain['host_os'] == 'linux' else "-" + toolchain['host_os']
    name = ('arm-gnu-toolchain-' +
            f'{toolchain["version"]}-{toolchain["host_arch"]}{host_os_name}-{toolchain["target"]}')
    toolchain['name'] = name

    target_os = 'linux' if 'linux' in toolchain['target'] else 'none'
    toolchain['target_os'] = target_os

    try:
      os.makedirs(
          os.path.join(toolchain_dir, 'tool_wrappers', toolchain['host_arch'], toolchain['host_os'],
                       toolchain['target'], toolchain['version']))
    except FileExistsError:
      pass

    toolchain['wrapper_paths'] = {}

    for tool in _ALL_TOOLS:
      tool_name = f'{toolchain["target"]}-{tool}'
      wrapper_path = os.path.join(toolchain_dir, 'tool_wrappers', toolchain['host_arch'],
                                  toolchain['host_os'], toolchain['target'], toolchain['version'],
                                  tool_name)
      toolchain['wrapper_paths'][tool] = os.path.relpath(wrapper_path, toolchain_dir)

      with open(wrapper_path, 'w') as f:
        f.write('#!/bin/bash\n')
        f.write(f'exec external/{name}/bin/{tool_name} $@\n')

      os.chmod(wrapper_path, 0o777)


def write_toolchain_info(filename):
  with open(filename, 'w') as f:
    f.write(f'AVAILABLE_TOOLCHAINS = {_AVAILABLE_TOOLCHAINS}\n')
    f.write(f'ALL_CPU = {_ALL_CPU}\n')


def write_test_script(filename):
  with open(filename, 'w') as f:
    f.write('#!/bin/bash\n')
    f.write('set -e\n')
    f.write('set -o xtrace\n\n')

    f.write('bazel clean\n')
    for toolchain in _AVAILABLE_TOOLCHAINS:
      for cpu in _ALL_CPU:
        platform = f'//platforms:{cpu}-{toolchain["target_os"]}-{toolchain["version"]}'
        f.write(f'bazel build -s --verbose_failures --platforms={platform} //test:test_cpp\n')
        f.write(f'bazel build -s --verbose_failures --platforms={platform} //test:test_c\n')

  os.chmod(filename, 0o777)


def main():
  parser = argparse.ArgumentParser(description='Generate wrapper scripts for Bazel toolchains.')
  args = parser.parse_args()

  root_dir = os.path.dirname(os.path.realpath(__file__))

  create_wrappers(os.path.join(root_dir, 'toolchains'))
  write_toolchain_info(os.path.join(root_dir, 'toolchains/toolchain_info.bzl'))
  write_test_script(os.path.join(root_dir, 'test_build_all.sh'))


if __name__ == '__main__':
  main()
