project(MyApp C CXX)
cmake_minimum_required(VERSION 2.8.12)

include(cmake/App.cmake)

set(SOURCES "src/MyApp.h"
            "src/MyApp.cpp"
            "src/main.cpp")

add_app("${SOURCES}")