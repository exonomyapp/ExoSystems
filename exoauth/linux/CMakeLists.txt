# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "exoauth")
project(${PROJECT_NAME} LANGUAGES CXX)

include("../cargokit/cmake/cargokit.cmake")
# --- EPHEMERAL SYMLINK SURVIVAL ---
# Flutter build processes often symlink plugins into ephemeral `.plugin_symlinks` folders.
# If we used simple relative paths (e.g. `../../`), Cargokit would get lost because `..`
# from a symlink resolves to the real source tree, breaking the path to the engine.
# By using REALPATH on `RUST_BUILDER_DIR` first, we establish our actual location in the
# monorepo before navigating to the detached `exotalk_engine`.
get_filename_component(RUST_BUILDER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/.." REALPATH)
get_filename_component(ENGINE_DIR "${RUST_BUILDER_DIR}/rust" REALPATH)
apply_cargokit(${PROJECT_NAME} ${ENGINE_DIR} exoauth_core "")

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(exoauth_bundled_libraries
  "${${PROJECT_NAME}_cargokit_lib}"
  PARENT_SCOPE
)
