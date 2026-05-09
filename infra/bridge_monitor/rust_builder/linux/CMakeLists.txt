cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "rust_lib_bridge_monitor")
project(${PROJECT_NAME} LANGUAGES CXX)

# 🧠 Educational Context: Native Library Integration
# We define the library as an IMPORTED target so Flutter can link it without expecting C++ sources.
add_library(${PROJECT_NAME} SHARED IMPORTED GLOBAL)
set_target_properties(${PROJECT_NAME} PROPERTIES
  IMPORTED_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/librust_lib_bridge_monitor.so"
)

# Build the Rust library via Cargo synchronously
add_custom_target(
  build_rust_lib_bridge_monitor ALL
  COMMAND cargo build --manifest-path "${CMAKE_CURRENT_SOURCE_DIR}/../Cargo.toml" --release
  COMMAND cp "${CMAKE_CURRENT_SOURCE_DIR}/../target/release/librust_lib_bridge_monitor.so" "${CMAKE_CURRENT_BINARY_DIR}/librust_lib_bridge_monitor.so"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/.."
  COMMENT "Building Rust library with Cargo..."
)

add_dependencies(${PROJECT_NAME} build_rust_lib_bridge_monitor)

# 🧠 Audit: Installation
# This is critical. It tells Flutter to copy our library into the bundle/lib folder.
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/librust_lib_bridge_monitor.so" DESTINATION "lib")
