This is a simple reproducer for NVIDIA bug 4139863 (https://developer.nvidia.com/bugs/4139863).
The problem is fixed in an upcoming CUDA 12.4 version.

## Description

Compiling the main() part of a Catch2 application with `nvcc` in c++20 mode leads to memory exhaustion inside `cudafe++`, likely due to an infinite loop.

## Reproducer

A reproducer can be as simple as `test.cu`:
```c++
#define CATCH_CONFIG_MAIN
#include <catch2/catch.hpp>
```

Compiling with `nvcc` in c++17 mode works fine:
```bash
/usr/local/cuda-12.1/bin/nvcc -std=c++17 test.cu -c -o test.o
```

Compiling with `nvcc` in c++20 seems to hang, and is eventually killed:
```bash
/usr/local/cuda-12.1/bin/nvcc -std=c++20 test.cu -c -o test.o
Killed
```

Investigatinh with `nvcc -v -keep` shows that the problem is in the `cudafe++` step:
```bash
/usr/local/cuda-12.1/bin/nvcc -std=c++20 test.cu -c -o test.o -v -keep -keep-dir tmp
...
gcc -std=c++20 -D__CUDA_ARCH_LIST__=520 -E -x c++ -D__CUDACC__ -D__NVCC__  "-I/usr/local/cuda-12.1/bin/../targets/x86_64-linux/include"    -D__CUDACC_VER_MAJOR__=12 -D__CUDACC_VER_MINOR__=1 -D__CUDACC_VER_BUILD__=105 -D__CUDA_API_VER_MAJOR__=12 -D__CUDA_API_VER_MINOR__=1 -D__NVCC_DIAG_PRAGMA_SUPPORT__=1 -include "cuda_runtime.h" -m64 "test.cu" -o "tmp/test.cpp4.ii"
cudafe++ --c++20 --gnu_version=110300 --display_error_number --orig_src_file_name "test.cu" --orig_src_path_name "/home/fwyzard/src/nvidia_bug_nnnnnnnn/test.cu" --allow_managed  --m64 --parse_templates --gen_c_file_name "tmp/test.cudafe1.cpp" --stub_file_name "test.cudafe1.stub.c" --gen_module_id_file --module_id_file_name "tmp/test.module_id" "tmp/test.cpp4.ii"
Killed
# --error 0x89 --
```

The last line of `tmp/test.cudafe1.cpp` is over 300 MB of repeating `std::remove_cv_t< const std::remove_cv_t< const std::remove_cv_t< const ...`, which points to some kind of infinite loop inside `cudafe++`.

---

A preprocessed source file `test.cu.ii` is also available, to avoid the need for installing Catch2.

It can be used together with the included Makefile to reproduce the crash, and show the start of the infinite-loop line that is being written:
```
export COLUMNS
make
...
Segmentation fault (core dumped)
std::remove_cv_t< const std::remove_cv_t< const std::remove_cv_t< const std::remove_cv_t< const std::remove_cv_t< const std::remove_cv_t< const std::remove_cv_t< const std::remove_cv_t< const std::remove_cv_t< ...
```
