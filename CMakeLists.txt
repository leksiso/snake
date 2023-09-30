cmake_minimum_required(VERSION 3.20)
include(../pico_sdk_import.cmake)
project(snake C CXX ASM)

set(CMAKE_VERBOSE_MAKEFILE ON)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

add_executable(snake
    snake.s
    helper.s
    pio_init_ledmatrix.c
)

pico_generate_pio_header(snake ${CMAKE_SOURCE_DIR}/ledmatrix.pio)

target_link_libraries(snake pico_stdlib hardware_pio)

pico_enable_stdio_uart(${PROJECT_NAME} 0)
pico_enable_stdio_usb(${PROJECT_NAME} 1)
pico_add_extra_outputs(${PROJECT_NAME})
