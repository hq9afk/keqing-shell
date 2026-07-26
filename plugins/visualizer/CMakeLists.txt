set(CMAKE_AUTOMOC ON)

if(COMMAND qt_policy)
    qt_policy(SET QTP0001 NEW)
endif()

find_package(PkgConfig REQUIRED)
pkg_check_modules(PW REQUIRED libpipewire-0.3)

qt_add_qml_module(keqingshell-visualizer
    URI KeqingShell.Visualizer
    SOURCES
        pwspectrum.hpp pwspectrum.cpp
        visualiserbars.hpp visualiserbars.cpp
)

target_compile_definitions(keqingshell-visualizer PRIVATE
    POCKETFFT_NO_MULTITHREADING
)

target_link_libraries(keqingshell-visualizer PRIVATE
    Qt::Core
    Qt::Qml
    Qt::Gui
    Qt::Quick
    ${PW_LIBRARIES}
)

target_include_directories(keqingshell-visualizer PRIVATE
    ${PW_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)

install(TARGETS keqingshell-visualizer
    LIBRARY DESTINATION "${INSTALL_QMLDIR}/KeqingShell/lib"
)

qt_query_qml_module(keqingshell-visualizer
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
