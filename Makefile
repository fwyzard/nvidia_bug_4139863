.PHONY: all clean

fail: module_id

all: test.o

clean:
	rm -f test.o cudafe1.cpp stub.c module_id

test.o: test.cu
	ulimit -v 2100000 && /usr/local/cuda-12.1/bin/nvcc -std=c++20 test.cu -c -o test.o

test.cu.ii: test.cu
	gcc -std=c++20 -D__CUDA_ARCH_LIST__=520 -E -x c++ -D__CUDACC__ -D__NVCC__ -I/usr/local/cuda-12.1/include -D__CUDACC_VER_MAJOR__=12 -D__CUDACC_VER_MINOR__=1 -D__CUDACC_VER_BUILD__=105 -D__CUDA_API_VER_MAJOR__=12 -D__CUDA_API_VER_MINOR__=1 -D__NVCC_DIAG_PRAGMA_SUPPORT__=1 -include "cuda_runtime.h" -m64 test.cu -o test.cu.ii

cudafe1.cpp stub.c module_id &: test.cu.ii
	ulimit -v 2100000 && /usr/local/cuda-12.1/bin/cudafe++ --c++20 --gnu_version=110300 --display_error_number --orig_src_file_name "test.cu" --orig_src_path_name "/home/fwyzard/src/nvidia_bug_4139863/test.cu" --allow_managed --m64 --parse_templates --gen_c_file_name "cudafe1.cpp" --stub_file_name "stub.c" --gen_module_id_file --module_id_file_name "module_id" test.cu.ii || tail -n1 cudafe1.cpp | cut -c -$(COLUMNS) | grep std::remove_cv_t
