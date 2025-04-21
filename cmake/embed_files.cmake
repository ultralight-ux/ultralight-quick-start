function(embed_files TARGET)
    cmake_parse_arguments(EMBED_FILES "" "" "FOLDERS" ${ARGN})

    set(EMBED_FILES_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/EmbeddedFiles")
    set(EMBED_FILES_HEADER "${EMBED_FILES_OUTPUT_DIR}/EmbeddedFiles.h")
    set(EMBED_FILES_RC "${EMBED_FILES_OUTPUT_DIR}/data.rc")

    # Find the Python executable
    find_package(Python COMPONENTS Interpreter)
    if(Python_FOUND)
        set(PYTHON_EXECUTABLE ${Python_EXECUTABLE})
    else()
        find_program(PYTHON_EXECUTABLE NAMES python python2 python3)
    endif()

    if(NOT PYTHON_EXECUTABLE)
        message(FATAL_ERROR "Python executable not found.")
    endif()

    # Find the embed_files.py script
    find_file(EMBED_FILES_SCRIPT NAMES embed_files.py PATHS ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_MODULE_PATH})

    if(NOT EMBED_FILES_SCRIPT)
        message(FATAL_ERROR "embed_files.py script not found.")
    endif()

    # Add the output directory to the target's include directories
    target_include_directories(${TARGET} PRIVATE ${EMBED_FILES_OUTPUT_DIR})

    # Create a custom target to run the embed_files.py script unconditionally
    add_custom_target(${TARGET}_embed_files
        COMMAND ${CMAKE_COMMAND} -E make_directory ${EMBED_FILES_OUTPUT_DIR}
        COMMAND ${PYTHON_EXECUTABLE} ${EMBED_FILES_SCRIPT} ${EMBED_FILES_FOLDERS} ${EMBED_FILES_OUTPUT_DIR}
        BYPRODUCTS ${EMBED_FILES_HEADER} ${EMBED_FILES_RC}
        COMMENT "Embedding files for target ${TARGET}"
        VERBATIM
    )

    if (${ALLINONE_BUILD})
        add_dependencies(${TARGET}_embed_files GenerateSDK)
    endif ()

    # Add the custom target as a dependency of the main target
    add_dependencies(${TARGET} ${TARGET}_embed_files)

    # Add the output header as a source file to the target
    target_sources(${TARGET} PRIVATE ${EMBED_FILES_HEADER})

    # Add the RC file to the target's source files on Windows
    if(WIN32)
        target_sources(${TARGET} PRIVATE ${EMBED_FILES_RC})
    endif()

    target_compile_definitions(${TARGET} PRIVATE UL_EMBED_FILES=1)
endfunction()