cmake_minimum_required(VERSION 3.16)
project(keqing-shell-plugins)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick Gui)
qt_standard_project_setup(REQUIRES 6.5)

if(NOT DEFINED INSTALL_QMLDIR)
    set(INSTALL_QMLDIR "lib/qt6/qml")
endif()

add_subdirectory(matrix)
add_subdirectory(visualizer)
