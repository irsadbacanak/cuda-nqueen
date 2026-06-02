cmake_minimum_required(VERSION 3.18)
project(nqueen LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD 17)

# Sistemdeki GPU'ya gore otomatik mimari algilama (CMake >= 3.24)
# Eski CMake'te elle belirtin: set(CMAKE_CUDA_ARCHITECTURES 75) vb.
if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES native)
endif()

add_executable(nqueen nqueen.cu)

target_compile_options(nqueen PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:
        -O3
        --use_fast_math
        -Xcompiler=-O3
    >
)

# Recursive __device__ fonksiyonlar icin gerekli
set_target_properties(nqueen PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
)
