include(CMakeParseArguments)
include(Platform)
include(embed_files)

if (${UL_ENABLE_STATIC_BUILD})
    include(StaticLibs)
endif ()

# Check if README.md exists in the SDK path
file(GLOB README_FILES "${UL_SDK_PATH}/README.md")
if (NOT README_FILES)
    message(FATAL_ERROR "Ultralight SDK not found at ${UL_SDK_PATH}. Please download the SDK and extract it to the correct path.")
endif ()

set(SDK_ROOT "${UL_SDK_PATH}")

set(ULTRALIGHT_INCLUDE_DIR "${SDK_ROOT}/include")
set(ULTRALIGHT_BINARY_DIR "${SDK_ROOT}/bin")
set(ULTRALIGHT_INSPECTOR_DIR "${SDK_ROOT}/inspector")
set(ULTRALIGHT_RESOURCES_DIR "${SDK_ROOT}/resources")
set(ULTRALIGHT_LIBRARY_DIR "${SDK_ROOT}/bin"
                           "${SDK_ROOT}/lib")

get_filename_component(INFO_PLIST_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Info.plist.in" REALPATH)
get_filename_component(ENTITLEMENTS_PLIST_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Entitlements.plist" REALPATH)

macro(add_console_app)
    set(APP_NAME ${ARGV0})
    set(options "NEEDS_INSPECTOR" "EMBED_FILES")
    set(oneValueArgs "")
    set(multiValueArgs "SOURCES")
    cmake_parse_arguments("ARGS"
                          "${options}"
                          "${oneValueArgs}"
                          "${multiValueArgs}"
                          ${ARGN})

    include_directories("${ULTRALIGHT_INCLUDE_DIR}")
    link_directories("${ULTRALIGHT_LIBRARY_DIR}")
    link_libraries(UltralightCore Ultralight WebCore AppCore)

    if (${UL_ENABLE_STATIC_BUILD})
        add_definitions(-DULTRALIGHT_STATIC_BUILD)
        link_libraries(${UL_STATIC_LIBS})
    endif ()

    if (UL_PLATFORM MATCHES "macos")
        set(CMAKE_INSTALL_RPATH ".")
    endif ()

    add_executable(${APP_NAME} ${ARGS_SOURCES})

    # Always link to the C++ standard library
    set_target_properties(${APP_NAME} PROPERTIES LINKER_LANGUAGE CXX)

    set(INSTALL_PATH "${APP_NAME}")

    install(TARGETS ${APP_NAME}
        RUNTIME DESTINATION "${INSTALL_PATH}"
        BUNDLE  DESTINATION "${INSTALL_PATH}")

    install(DIRECTORY "${ULTRALIGHT_BINARY_DIR}/" DESTINATION "${INSTALL_PATH}")
    install(DIRECTORY "${ULTRALIGHT_RESOURCES_DIR}" DESTINATION "${INSTALL_PATH}/assets")
    install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/assets/" DESTINATION "${INSTALL_PATH}/assets" OPTIONAL)

    # Conditionally embed additional assets based on EMBED_FILES
    if (ARGS_EMBED_FILES)
    endif ()
        
endmacro ()

macro(add_app)
    set(APP_NAME ${ARGV0})
    set(prefix "ARGS")
    set(options "NEEDS_INSPECTOR" "EMBED_FILES")
    set(oneValueArgs "")
    set(multiValueArgs "SOURCES")
    cmake_parse_arguments(${prefix}
                          "${options}"
                          "${oneValueArgs}"
                          "${multiValueArgs}"
                          ${ARGN})

    include_directories("${ULTRALIGHT_INCLUDE_DIR}")
    link_directories("${ULTRALIGHT_LIBRARY_DIR}")
    link_libraries(UltralightCore AppCore Ultralight WebCore)

    if (${UL_ENABLE_STATIC_BUILD})
        add_definitions(-DULTRALIGHT_STATIC_BUILD)
        link_libraries(${UL_STATIC_LIBS} ${APPCORE_STATIC_LIBS})
    endif ()

    add_executable(${APP_NAME} WIN32 MACOSX_BUNDLE ${ARGS_SOURCES})

    # Always link to the C++ standard library
    set_target_properties(${APP_NAME} PROPERTIES LINKER_LANGUAGE CXX)

    if (ARGS_EMBED_FILES)
        set(EMBEDDED_FOLDERS "${CMAKE_CURRENT_SOURCE_DIR}/assets/"
                             "${ULTRALIGHT_RESOURCES_DIR}")

        if (ARGS_NEEDS_INSPECTOR)
            list(APPEND EMBEDDED_FOLDERS "${ULTRALIGHT_INSPECTOR_DIR}")
        endif ()

        embed_files(${APP_NAME} FOLDERS ${EMBEDDED_FOLDERS})
    endif ()

    set(INSTALL_PATH "${APP_NAME}")

    if (UL_PLATFORM MATCHES "macos")
        # Include Entitlements.plist
        set_source_files_properties(${ENTITLEMENTS_PLIST_PATH} PROPERTIES MACOSX_PACKAGE_LOCATION "Contents")

        # Enable High-DPI on macOS through our custom Info.plist template
        set_target_properties(${APP_NAME} PROPERTIES
            BUNDLE True
            MACOSX_BUNDLE_GUI_IDENTIFIER ultralight.${APP_NAME}
            MACOSX_BUNDLE_BUNDLE_NAME ${APP_NAME}
            MACOSX_BUNDLE_EXECUTABLE_NAME ${APP_NAME}
            MACOSX_BUNDLE_BUNDLE_VERSION "1.0"
            MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
            MACOSX_BUNDLE_INFO_PLIST ${INFO_PLIST_PATH}
        )

        # Set the install destination for the app bundle
        set(BUNDLE_INSTALL_PATH "${INSTALL_PATH}/${APP_NAME}.app")
        set(BUNDLE_EXEC_PATH "${BUNDLE_INSTALL_PATH}/Contents/MacOS")
        set(BUNDLE_RESOURCE_PATH "${BUNDLE_INSTALL_PATH}/Contents/Resources")
        set(BUNDLE_ASSETS_PATH "${BUNDLE_RESOURCE_PATH}/assets")

        install(TARGETS ${APP_NAME} BUNDLE DESTINATION "${INSTALL_PATH}")
        install(DIRECTORY "${ULTRALIGHT_BINARY_DIR}/" DESTINATION "${BUNDLE_EXEC_PATH}")
        
        if (NOT ARGS_EMBED_FILES)
            install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/assets/" DESTINATION "${BUNDLE_ASSETS_PATH}" OPTIONAL)
            install(DIRECTORY "${ULTRALIGHT_RESOURCES_DIR}" DESTINATION "${BUNDLE_ASSETS_PATH}")
            if (ARGS_NEEDS_INSPECTOR)
                install(DIRECTORY "${ULTRALIGHT_INSPECTOR_DIR}" DESTINATION "${BUNDLE_ASSETS_PATH}")
            endif()
        endif()
        
    else ()
        if (UL_PLATFORM MATCHES "windows")
            # Use main instead of WinMain for Windows subsystem executables
            set_target_properties(${APP_NAME} PROPERTIES LINK_FLAGS "/ENTRY:mainCRTStartup")
        endif()

        set(ASSETS_PATH "${INSTALL_PATH}/assets")
        set(BIN_PATH "${INSTALL_PATH}")

        install(TARGETS ${APP_NAME} RUNTIME DESTINATION "${INSTALL_PATH}")
        install(DIRECTORY "${ULTRALIGHT_BINARY_DIR}/" DESTINATION "${BIN_PATH}")

        if (NOT ARGS_EMBED_FILES)
            install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/assets/" DESTINATION "${ASSETS_PATH}" OPTIONAL)
            install(DIRECTORY "${ULTRALIGHT_RESOURCES_DIR}" DESTINATION "${ASSETS_PATH}")
            if (ARGS_NEEDS_INSPECTOR)
                install(DIRECTORY "${ULTRALIGHT_INSPECTOR_DIR}" DESTINATION "${ASSETS_PATH}")
            endif()
        endif()
    endif ()
endmacro ()