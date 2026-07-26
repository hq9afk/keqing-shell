set(CMAKE_AUTOMOC ON)

if(COMMAND qt_policy)
    qt_policy(SET QTP0001 NEW)
endif()

qt_add_qml_module(keqingshell-matrix
    URI KeqingShell.Matrix
    SOURCES
        matrixgrid.hpp matrixgrid.cpp
)

target_link_libraries(keqingshell-matrix PRIVATE
    Qt::Core
    Qt::Qml
    Qt::Gui
    Qt::Quick
)

target_include_directories(keqingshell-matrix PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

install(TARGETS keqingshell-matrix
    LIBRARY DESTINATION "${INSTALL_QMLDIR}/KeqingShell/lib"
)

qt_query_qml_module(keqingshell-matrix
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
