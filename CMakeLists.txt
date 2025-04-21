cmake_minimum_required(VERSION 3.15.0)
project(MyApp C CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

get_filename_component(UL_SDK_PATH "${CMAKE_CURRENT_SOURCE_DIR}/SDK" REALPATH)
list(PREPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/out" CACHE PATH "Install prefix" FORCE)
include(Common)

# Set this to TRUE to embed assets directly into the executable.
set(SHOULD_EMBED_FILES FALSE)

# Set your source files here.
set(SOURCE_FILES "src/MyApp.h"
                 "src/MyApp.cpp"
                 "src/main.cpp")

if (SHOULD_EMBED_FILES)
	set(SOURCE_FILES ${SOURCE_FILES}
					 "src/platform/EmbeddedFileSystem.h"
					 "src/platform/EmbeddedFileSystem.cpp")
    add_app(MyApp EMBED_FILES SOURCES ${SOURCE_FILES})
else ()
    add_app(MyApp SOURCES ${SOURCE_FILES})
endif ()