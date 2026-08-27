cmake_minimum_required(VERSION 3.16)
project(keqing-shell-plugins)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick Gui)
qt_standard_project_setup(REQUIRES 6.5)

find_package(PkgConfig REQUIRED)
pkg_check_modules(PW REQUIRED libpipewire-0.3)

set(CMAKE_AUTOMOC ON)
if(COMMAND qt_policy)
    qt_policy(SET QTP0001 NEW)
endif()

if(NOT DEFINED INSTALL_QMLDIR)
    set(INSTALL_QMLDIR "lib/qt6/qml")
endif()

# Install a qt_add_qml_module target plus its generated plugin/qmldir/typeinfo.
function(install_qml_module target)
    install(TARGETS ${target}
        LIBRARY DESTINATION "${INSTALL_QMLDIR}/KeqingShell/lib"
    )
    qt_query_qml_module(${target}
        PLUGIN_TARGET plugin_target
        TARGET_PATH target_path
        QMLDIR qmldir_file
        TYPEINFO typeinfo_file
    )
    install(TARGETS ${plugin_target}
        LIBRARY DESTINATION "${INSTALL_QMLDIR}/${target_path}"
    )
    install(FILES "${qmldir_file}" "${typeinfo_file}"
        DESTINATION "${INSTALL_QMLDIR}/${target_path}"
    )
endfunction()

# KeqingShell.Matrix
qt_add_qml_module(keqingshell-matrix
    URI KeqingShell.Matrix
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/KeqingShell/Matrix"
    SOURCES
        matrix/matrixgrid.hpp matrix/matrixgrid.cpp
)
target_link_libraries(keqingshell-matrix PRIVATE
    Qt::Core Qt::Qml Qt::Gui Qt::Quick
)
target_include_directories(keqingshell-matrix PRIVATE matrix)
install_qml_module(keqingshell-matrix)

# KeqingShell.Visualizer
qt_add_qml_module(keqingshell-visualizer
    URI KeqingShell.Visualizer
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/KeqingShell/Visualizer"
    SOURCES
        visualizer/pwspectrum.hpp visualizer/pwspectrum.cpp
        visualizer/visualizerbars.hpp visualizer/visualizerbars.cpp
        visualizer/gradientinterp.hpp
)
target_compile_definitions(keqingshell-visualizer PRIVATE
    POCKETFFT_NO_MULTITHREADING
)
target_link_libraries(keqingshell-visualizer PRIVATE
    Qt::Core Qt::Qml Qt::Gui Qt::Quick
    ${PW_LIBRARIES}
)
target_include_directories(keqingshell-visualizer PRIVATE
    ${PW_INCLUDE_DIRS}
    visualizer
)
install_qml_module(keqingshell-visualizer)
