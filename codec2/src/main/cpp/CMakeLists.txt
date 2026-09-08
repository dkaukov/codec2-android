cmake_minimum_required(VERSION 3.22.1)
project(codec2_android LANGUAGES C CXX)

include(FetchContent)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(LPCNET OFF CACHE BOOL "" FORCE)
set(UNITTEST OFF CACHE BOOL "" FORCE)
set(CODEC2_MODE_EN_DEFAULT 0 CACHE STRING "" FORCE)
set(CODEC2_MODE_1300_EN 1 CACHE STRING "" FORCE)
set(FREEDV_MODE_EN_DEFAULT 0 CACHE STRING "" FORCE)

# Codec2 1.2.0 is pinned to the commit behind its release tag so builds are reproducible.
FetchContent_Declare(codec2_upstream
    GIT_REPOSITORY https://github.com/drowe67/codec2.git
    GIT_TAG 06d4c11e699b0351765f10398abb4f663a984f36
    GIT_SHALLOW FALSE)
FetchContent_GetProperties(codec2_upstream)
if(NOT codec2_upstream_POPULATED)
    FetchContent_Populate(codec2_upstream)
endif()

set(C2 ${codec2_upstream_SOURCE_DIR}/src)
set(C2GEN ${codec2_upstream_BINARY_DIR}/generated)
file(MAKE_DIRECTORY ${C2GEN}/codec2)

# generate_codebook is a host executable. It must run while configuring the
# Android cross-build, so compile it with the host compiler rather than NDK clang.
find_program(HOST_C_COMPILER NAMES cc clang gcc REQUIRED)
set(CODEBOOK_GENERATOR ${codec2_upstream_BINARY_DIR}/generate_codebook)
execute_process(
    COMMAND ${HOST_C_COMPILER} ${C2}/generate_codebook.c -o ${CODEBOOK_GENERATOR} -lm
    RESULT_VARIABLE CODEBOOK_COMPILER_RESULT)
if(NOT CODEBOOK_COMPILER_RESULT EQUAL 0)
    message(FATAL_ERROR "Unable to build Codec2 codebook generator")
endif()

function(generate_codec2_codebook output symbol)
    execute_process(
        COMMAND ${CODEBOOK_GENERATOR} ${symbol} ${ARGN}
        OUTPUT_FILE ${C2GEN}/${output}
        RESULT_VARIABLE CODEBOOK_RESULT)
    if(NOT CODEBOOK_RESULT EQUAL 0)
        message(FATAL_ERROR "Unable to generate Codec2 ${output}")
    endif()
endfunction()

set(CB ${C2}/codebook)
generate_codec2_codebook(codebook.c lsp_cb
    ${CB}/lsp1.txt ${CB}/lsp2.txt ${CB}/lsp3.txt ${CB}/lsp4.txt ${CB}/lsp5.txt
    ${CB}/lsp6.txt ${CB}/lsp7.txt ${CB}/lsp8.txt ${CB}/lsp9.txt ${CB}/lsp10.txt)
set(CODEC2_VERSION_MAJOR 1)
set(CODEC2_VERSION_MINOR 2)
set(CODEC2_VERSION_PATCH 0)
set(CODEC2_VERSION "1.2.0")
configure_file(${codec2_upstream_SOURCE_DIR}/cmake/version.h.in
    ${C2GEN}/codec2/version.h)

# This deliberately contains only the implementation needed by CODEC2_MODE_1300.
add_library(codec2 SHARED
    ${C2}/codec2.c ${C2}/codec2_fft.c ${C2}/dump.c
    ${C2}/interp.c ${C2}/kiss_fft.c ${C2}/kiss_fftr.c
    ${C2}/lpc.c ${C2}/lsp.c ${C2}/nlp.c
    ${C2}/pack.c ${C2}/phase.c ${C2}/postfilter.c ${C2}/quantise.c ${C2}/sine.c
    ${C2GEN}/codebook.c)

target_compile_definitions(codec2 PRIVATE
    CODEC2_MODE_EN_DEFAULT=0 CODEC2_MODE_1300_EN=1)
target_include_directories(codec2 PUBLIC ${C2} ${C2GEN} ${C2GEN}/codec2)
target_compile_options(codec2 PRIVATE -ffunction-sections -fdata-sections)
target_link_options(codec2 PRIVATE
    -Wl,--gc-sections
    -Wl,--no-undefined
    -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/codec2.exports.map)
target_link_libraries(codec2 PRIVATE m)

add_library(codec2-android SHARED codec2_jni.cpp)
target_link_libraries(codec2-android PRIVATE codec2 log)
