#
# Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
# Copyright (C) 2021+ WarheadCore <https://github.com/WarheadCore>
#
# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY, to the extent permitted by law; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#

CU_RUN_HOOK(BEFORE_SCRIPTS_LIBRARY)

message("")

# Make the script module list available in the current scope
GetScriptModuleList(SCRIPT_MODULE_LIST)
GetModuleSourceList(MODULES_MODULE_LIST)

# Make the native install offset available in this scope
GetInstallOffset(INSTALL_OFFSET)

# Sets the SCRIPTS_${SCRIPT_MODULE} variables
# when using predefined templates for script building
# like dynamic, static, minimal-static...
# Sets SCRIPTS_DEFAULT_LINKAGE
if(SCRIPTS MATCHES "dynamic")
  set(SCRIPTS_DEFAULT_LINKAGE "dynamic")
elseif(SCRIPTS MATCHES "static")
  set(SCRIPTS_DEFAULT_LINKAGE "static")
else()
  set(SCRIPTS_DEFAULT_LINKAGE "disabled")
endif()

# Sets the MODULES_${SOURCE_MODULE} variables
# when using predefined templates for script building
# like dynamic, static
# Sets MODULES_DEFAULT_LINKAGE
if(MODULES MATCHES "dynamic")
  set(MODULES_DEFAULT_LINKAGE "dynamic")
elseif(MODULES MATCHES "static")
  set(MODULES_DEFAULT_LINKAGE "static")
else()
  set(MODULES_DEFAULT_LINKAGE "disabled")
endif()

# Sets SCRIPTS_USE_WHITELIST
# Sets SCRIPTS_WHITELIST
if(SCRIPTS MATCHES "minimal")
  set(SCRIPTS_USE_WHITELIST ON)
  # Whitelist which is used when minimal is selected
  list(APPEND SCRIPTS_WHITELIST Commands Spells)
endif()

# Add support old api modules
CU_GET_GLOBAL("AC_ADD_SCRIPTS_LIST")
CU_GET_GLOBAL("AC_ADD_SCRIPTS_INCLUDE")

set("AC_SCRIPTS_INCLUDES" "")
set("AC_MODULE_LIST" "")
set("AC_SCRIPTS_LIST" "")

foreach(include ${AC_ADD_SCRIPTS_INCLUDE})
  set("AC_SCRIPTS_INCLUDES" "#include \"${include}\"\n${AC_SCRIPTS_INCLUDES}")
endforeach()

foreach(void ${AC_ADD_SCRIPTS_LIST})
  set("AC_MODULE_LIST" "void ${void};\n${AC_MODULE_LIST}")
endforeach()

foreach(scriptName ${AC_ADD_SCRIPTS_LIST})
  set("AC_SCRIPTS_LIST" "    ${scriptName};\n${AC_SCRIPTS_LIST}")
endforeach()

# Set the SCRIPTS_${SCRIPT_MODULE} variables from the
# variables set above
foreach(SCRIPT_MODULE ${SCRIPT_MODULE_LIST})
  ScriptModuleNameToVariable(${SCRIPT_MODULE} SCRIPT_MODULE_VARIABLE)

  if(${SCRIPT_MODULE_VARIABLE} STREQUAL "default")
    if(SCRIPTS_USE_WHITELIST)
      list(FIND SCRIPTS_WHITELIST "${SCRIPT_MODULE}" INDEX)
      if(${INDEX} GREATER -1)
        set(${SCRIPT_MODULE_VARIABLE} ${SCRIPTS_DEFAULT_LINKAGE})
      else()
        set(${SCRIPT_MODULE_VARIABLE} "disabled")
      endif()
    else()
      set(${SCRIPT_MODULE_VARIABLE} ${SCRIPTS_DEFAULT_LINKAGE})
    endif()
  endif()

  # Build the Graph values
  if(${SCRIPT_MODULE_VARIABLE} MATCHES "dynamic")
    GetProjectNameOfScriptModule(${SCRIPT_MODULE} SCRIPT_MODULE_PROJECT_NAME)
    GetNativeSharedLibraryName(${SCRIPT_MODULE_PROJECT_NAME} SCRIPT_PROJECT_LIBRARY)
    list(APPEND SCRIPT_GRAPH_KEYS ${SCRIPT_MODULE_PROJECT_NAME})
    set(SCRIPT_GRAPH_VALUE_DISPLAY_${SCRIPT_MODULE_PROJECT_NAME} ${SCRIPT_PROJECT_LIBRARY})
    list(APPEND SCRIPT_GRAPH_VALUE_CONTAINS_MODULES_${SCRIPT_MODULE_PROJECT_NAME} ${SCRIPT_MODULE})
  elseif(${SCRIPT_MODULE_VARIABLE} MATCHES "static")
    list(APPEND SCRIPT_GRAPH_KEYS worldserver)
    set(SCRIPT_GRAPH_VALUE_DISPLAY_worldserver worldserver)
    list(APPEND SCRIPT_GRAPH_VALUE_CONTAINS_MODULES_worldserver ${SCRIPT_MODULE})
  else()
    list(APPEND SCRIPT_GRAPH_KEYS disabled)
    set(SCRIPT_GRAPH_VALUE_DISPLAY_disabled disabled)
    list(APPEND SCRIPT_GRAPH_VALUE_CONTAINS_MODULES_disabled ${SCRIPT_MODULE})
  endif()
endforeach()

# Set the MODULES_${SOURCE_MODULE} variables from the
# variables set above
foreach(SOURCE_MODULE ${MODULES_MODULE_LIST})
  ModuleNameToVariable(${SOURCE_MODULE} MODULE_MODULE_VARIABLE)

  if(${MODULE_MODULE_VARIABLE} STREQUAL "default")
    set(${MODULE_MODULE_VARIABLE} ${MODULES_DEFAULT_LINKAGE})
  endif()

  # Use only static for deprecated api loaders
  if (AC_SCRIPTS_INCLUDES MATCHES "${SOURCE_MODULE}")
    set(${MODULE_MODULE_VARIABLE} "static")
  endif()

  # Use only static for mod-eluna-lua-engine
  if (SOURCE_MODULE MATCHES "mod-eluna-lua-engine")
    set(${MODULE_MODULE_VARIABLE} "static")
  endif()

  # Build the Graph values
  if(${MODULE_MODULE_VARIABLE} MATCHES "dynamic")
    GetProjectNameOfModuleName(${SOURCE_MODULE} MODULE_SOURCE_PROJECT_NAME)
    GetNativeSharedLibraryName(${MODULE_SOURCE_PROJECT_NAME} MODULE_PROJECT_LIBRARY)
    list(APPEND MODULE_GRAPH_KEYS ${MODULE_SOURCE_PROJECT_NAME})
    set(MODULE_GRAPH_VALUE_DISPLAY_${MODULE_SOURCE_PROJECT_NAME} ${MODULE_PROJECT_LIBRARY})
    list(APPEND MODULE_GRAPH_VALUE_CONTAINS_MODULES_${MODULE_SOURCE_PROJECT_NAME} ${SOURCE_MODULE})
  elseif(${MODULE_MODULE_VARIABLE} MATCHES "static")
    list(APPEND MODULE_GRAPH_KEYS worldserver)
    set(MODULE_GRAPH_VALUE_DISPLAY_worldserver worldserver)
    list(APPEND MODULE_GRAPH_VALUE_CONTAINS_MODULES_worldserver ${SOURCE_MODULE})
  else()
    list(APPEND MODULE_GRAPH_KEYS disabled)
    set(MODULE_GRAPH_VALUE_DISPLAY_disabled disabled)
    list(APPEND MODULE_GRAPH_VALUE_CONTAINS_MODULES_disabled ${SOURCE_MODULE})
  endif()
endforeach()

list(SORT SCRIPT_GRAPH_KEYS)
list(SORT MODULE_GRAPH_KEYS)
list(REMOVE_DUPLICATES SCRIPT_GRAPH_KEYS)
list(REMOVE_DUPLICATES MODULE_GRAPH_KEYS)

# Display the script graph
message("* Script configuration (${SCRIPTS}):
  |")

foreach(SCRIPT_GRAPH_KEY ${SCRIPT_GRAPH_KEYS})
  if(NOT SCRIPT_GRAPH_KEY STREQUAL "disabled")
    message("  +- ${SCRIPT_GRAPH_VALUE_DISPLAY_${SCRIPT_GRAPH_KEY}}")
  else()
    message("  |  ${SCRIPT_GRAPH_VALUE_DISPLAY_${SCRIPT_GRAPH_KEY}}")
  endif()
  foreach(SCRIPT_GRAPH_PROJECT_ENTRY ${SCRIPT_GRAPH_VALUE_CONTAINS_MODULES_${SCRIPT_GRAPH_KEY}})
    message("  |   +- ${SCRIPT_GRAPH_PROJECT_ENTRY}")
  endforeach()
  message("  |")
endforeach()

message("")

# Display the module graph
message("* Modules configuration (${MODULES}):
  |")

foreach(MODULE_GRAPH_KEY ${MODULE_GRAPH_KEYS})
  if(NOT MODULE_GRAPH_KEY STREQUAL "disabled")
    message("  +- ${MODULE_GRAPH_VALUE_DISPLAY_${MODULE_GRAPH_KEY}}")
  else()
    message("  |  ${MODULE_GRAPH_VALUE_DISPLAY_${MODULE_GRAPH_KEY}}")
  endif()
  foreach(MODULE_GRAPH_PROJECT_ENTRY ${MODULE_GRAPH_VALUE_CONTAINS_MODULES_${MODULE_GRAPH_KEY}})
    message("  |   +- ${MODULE_GRAPH_PROJECT_ENTRY}")
  endforeach()
  message("  |")
endforeach()

message("")

# Base sources which are used by every script project
if(USE_SCRIPTPCH)
  set(PRIVATE_PCH_HEADER ScriptPCH.h)
endif()

GroupSources(${CMAKE_CURRENT_SOURCE_DIR})

# Configures the scriptloader with the given name and stores the output in the LOADER_OUT variable.
# It is possible to expose multiple subdirectories from the same scriptloader through passing
# it to the variable arguments
function(ConfigureScriptLoader SCRIPTLOADER_NAME LOADER_OUT IS_DYNAMIC_SCRIPTLOADER)
  # Deduces following variables which are referenced by thge template:
  # ACORE_IS_DYNAMIC_SCRIPTLOADER
  # ACORE_SCRIPTS_FORWARD_DECL
  # ACORE_SCRIPTS_INVOKE
  # ACORE_CURRENT_SCRIPT_PROJECT

  # To generate export macros
  set(ACORE_IS_DYNAMIC_SCRIPTLOADER ${IS_DYNAMIC_SCRIPTLOADER})

  # To generate forward declarations of the loading functions
  unset(ACORE_SCRIPTS_FORWARD_DECL)
  unset(ACORE_SCRIPTS_INVOKE)

  # The current script project which is built in
  set(ACORE_CURRENT_SCRIPT_PROJECT ${SCRIPTLOADER_NAME})

  foreach(LOCALE_SCRIPT_MODULE ${ARGN})

    # Replace bad words
    string(REGEX REPLACE - "_" LOCALE_SCRIPT_MODULE ${LOCALE_SCRIPT_MODULE})

    # Determine the loader function ("Add##${NameOfDirectory}##Scripts()")
    set(LOADER_FUNCTION
      "Add${LOCALE_SCRIPT_MODULE}Scripts()")

    # Generate the funciton call and the forward declarations
    set(ACORE_SCRIPTS_FORWARD_DECL
      "${ACORE_SCRIPTS_FORWARD_DECL}void ${LOADER_FUNCTION};\n")

    set(ACORE_SCRIPTS_INVOKE
      "${ACORE_SCRIPTS_INVOKE}    ${LOADER_FUNCTION};\n")
  endforeach()

  set(GENERATED_LOADER ${CMAKE_CURRENT_BINARY_DIR}/gen_scriptloader/${SCRIPTLOADER_NAME}/ScriptLoader.cpp)
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/ScriptLoader.cpp.in.cmake ${GENERATED_LOADER})
  set(${LOADER_OUT} ${GENERATED_LOADER} PARENT_SCOPE)
endfunction()

# Generates the actual script projects
# Fills the STATIC_SCRIPT_MODULES and DYNAMIC_SCRIPT_MODULE_PROJECTS variables
# which contain the names which scripts are linked statically/dynamically and
# adds the sources of the static modules to the PRIVATE_SOURCES variable.
foreach(SCRIPT_MODULE ${SCRIPT_MODULE_LIST})
  GetPathToScriptModule(${SCRIPT_MODULE} SCRIPT_MODULE_PATH)
  ScriptModuleNameToVariable(${SCRIPT_MODULE} SCRIPT_MODULE_VARIABLE)

  if((${SCRIPT_MODULE_VARIABLE} STREQUAL "disabled") OR
      (${SCRIPT_MODULE_VARIABLE} STREQUAL "static"))
    # Uninstall disabled modules
    GetProjectNameOfScriptModule(${SCRIPT_MODULE} SCRIPT_MODULE_PROJECT_NAME)
    GetNativeSharedLibraryName(${SCRIPT_MODULE_PROJECT_NAME} SCRIPT_MODULE_OUTPUT_NAME)
    list(APPEND DISABLED_SCRIPT_MODULE_PROJECTS ${INSTALL_OFFSET}/${SCRIPT_MODULE_OUTPUT_NAME})
    if(${SCRIPT_MODULE_VARIABLE} STREQUAL "static")
      # Add the module name to STATIC_SCRIPT_MODULES
      list(APPEND STATIC_SCRIPT_MODULES ${SCRIPT_MODULE})
      # Add the module content to the whole static module
      CollectSourceFiles(${SCRIPT_MODULE_PATH} PRIVATE_SOURCES)
    endif()
  elseif(${SCRIPT_MODULE_VARIABLE} STREQUAL "dynamic")

    # Generate an own dynamic module which is loadable on runtime
    # Add the module content to the whole static module
    unset(SCRIPT_MODULE_PRIVATE_SOURCES)
    CollectSourceFiles(${SCRIPT_MODULE_PATH} SCRIPT_MODULE_PRIVATE_SOURCES)

    # Configure the scriptloader
    ConfigureScriptLoader(${SCRIPT_MODULE} SCRIPT_MODULE_PRIVATE_SCRIPTLOADER ON ${SCRIPT_MODULE})
    GetProjectNameOfScriptModule(${SCRIPT_MODULE} SCRIPT_MODULE_PROJECT_NAME)

    # Add the module name to DYNAMIC_SCRIPT_MODULES
    list(APPEND DYNAMIC_SCRIPT_MODULE_PROJECTS ${SCRIPT_MODULE_PROJECT_NAME})

    # Create the script module project
    add_library(${SCRIPT_MODULE_PROJECT_NAME} SHARED
      ${SCRIPT_MODULE_PRIVATE_SOURCES}
      ${SCRIPT_MODULE_PRIVATE_SCRIPTLOADER})

    target_link_libraries(${SCRIPT_MODULE_PROJECT_NAME}
      PRIVATE
        acore-core-interface
      PUBLIC
        game)

    target_include_directories(${SCRIPT_MODULE_PROJECT_NAME}
      PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR})

    set_target_properties(${SCRIPT_MODULE_PROJECT_NAME}
      PROPERTIES
        FOLDER
          "scripts")

    if(UNIX)
      install(TARGETS ${SCRIPT_MODULE_PROJECT_NAME}
        DESTINATION ${INSTALL_OFFSET} COMPONENT ${SCRIPT_MODULE_PROJECT_NAME})
    elseif(WIN32)
      install(TARGETS ${SCRIPT_MODULE_PROJECT_NAME}
        RUNTIME DESTINATION ${INSTALL_OFFSET} COMPONENT ${SCRIPT_MODULE_PROJECT_NAME})
      if(MSVC)
        # Place the script modules in the script subdirectory
        set_target_properties(${SCRIPT_MODULE_PROJECT_NAME} PROPERTIES
          RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/bin/Debug/scripts
          RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/bin/Release/scripts
          RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${CMAKE_BINARY_DIR}/bin/RelWithDebInfo/scripts
          RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL ${CMAKE_BINARY_DIR}/bin/MinSizeRel/scripts)
      endif()
    endif()
  else()
    message(FATAL_ERROR "Unknown value \"${${SCRIPT_MODULE_VARIABLE}}\"!")
  endif()
endforeach()

# Generates the actual module projects
# Fills the STATIC_SCRIPT_MODULES and DYNAMIC_SCRIPT_MODULE_PROJECTS variables
# which contain the names which scripts are linked statically/dynamically and
# adds the sources of the static modules to the PRIVATE_SOURCES variable.
foreach(SOURCE_MODULE ${MODULES_MODULE_LIST})
  GetPathToModuleSource(${SOURCE_MODULE} MODULE_SOURCE_PATH)
  ModuleNameToVariable(${SOURCE_MODULE} MODULE_MODULE_VARIABLE)

  if((${MODULE_MODULE_VARIABLE} STREQUAL "disabled") OR
      (${MODULE_MODULE_VARIABLE} STREQUAL "static"))

    # Uninstall disabled modules
    GetProjectNameOfModuleName(${SOURCE_MODULE} MODULE_SOURCE_PROJECT_NAME)
    GetNativeSharedLibraryName(${MODULE_SOURCE_PROJECT_NAME} SCRIPT_MODULE_OUTPUT_NAME)
    list(APPEND DISABLED_SCRIPT_MODULE_PROJECTS ${INSTALL_OFFSET}/${SCRIPT_MODULE_OUTPUT_NAME})
    if(${MODULE_MODULE_VARIABLE} STREQUAL "static")

      # Add the module content to the whole static module
      CollectSourceFiles(${MODULE_SOURCE_PATH} PRIVATE_SOURCES)

      # Skip deprecated api loaders
      if (AC_SCRIPTS_INCLUDES MATCHES "${SOURCE_MODULE}")
        message("> Module (${SOURCE_MODULE}) using deprecated loader api")
        continue()
      endif()

      # Skip mod-eluna-lua-engine
      if (SOURCE_MODULE MATCHES "mod-eluna-lua-engine")
        continue()
      endif()

      # Add the module name to STATIC_SCRIPT_MODULES
      list(APPEND STATIC_SCRIPT_MODULES ${SOURCE_MODULE})

    endif()
  elseif(${MODULE_MODULE_VARIABLE} STREQUAL "dynamic")

    # Generate an own dynamic module which is loadable on runtime
    # Add the module content to the whole static module
    unset(MODULE_SOURCE_PRIVATE_SOURCES)
    CollectSourceFiles(${MODULE_SOURCE_PATH} MODULE_SOURCE_PRIVATE_SOURCES)

    # Configure the scriptloader
    ConfigureScriptLoader(${SOURCE_MODULE} SCRIPT_MODULE_PRIVATE_SCRIPTLOADER ON ${SOURCE_MODULE})
    GetProjectNameOfModuleName(${SOURCE_MODULE} MODULE_SOURCE_PROJECT_NAME)

    # Add the module name to DYNAMIC_SCRIPT_MODULES
    list(APPEND DYNAMIC_SCRIPT_MODULE_PROJECTS ${MODULE_SOURCE_PROJECT_NAME})

    # Create the script module project
    add_library(${MODULE_SOURCE_PROJECT_NAME} SHARED
      ${MODULE_SOURCE_PRIVATE_SOURCES}
      ${SCRIPT_MODULE_PRIVATE_SCRIPTLOADER})

    target_link_libraries(${MODULE_SOURCE_PROJECT_NAME}
      PRIVATE
        acore-core-interface
      PUBLIC
        game)

    target_include_directories(${MODULE_SOURCE_PROJECT_NAME}
      PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR})

    set_target_properties(${MODULE_SOURCE_PROJECT_NAME}
      PROPERTIES
        FOLDER
          "scripts")

    if(UNIX)
      install(TARGETS ${MODULE_SOURCE_PROJECT_NAME}
        DESTINATION ${INSTALL_OFFSET} COMPONENT ${MODULE_SOURCE_PROJECT_NAME})
    elseif(WIN32)
      install(TARGETS ${MODULE_SOURCE_PROJECT_NAME}
        RUNTIME DESTINATION ${INSTALL_OFFSET} COMPONENT ${MODULE_SOURCE_PROJECT_NAME})
      if(MSVC)
        # Place the script modules in the script subdirectory
        set_target_properties(${MODULE_SOURCE_PROJECT_NAME} PROPERTIES
          RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/bin/Debug/scripts
          RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/bin/Release/scripts
          RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${CMAKE_BINARY_DIR}/bin/RelWithDebInfo/scripts
          RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL ${CMAKE_BINARY_DIR}/bin/MinSizeRel/scripts)
      endif()
    endif()
  else()
    message(FATAL_ERROR "Unknown value \"${${MODULE_MODULE_VARIABLE}}\" for module (${SOURCE_MODULE})!")
  endif()
endforeach()

# Add the dynamic script modules to the worldserver as dependency
set(WORLDSERVER_DYNAMIC_SCRIPT_MODULES_DEPENDENCIES ${DYNAMIC_SCRIPT_MODULE_PROJECTS} PARENT_SCOPE)

ConfigureScriptLoader("static" SCRIPT_MODULE_PRIVATE_SCRIPTLOADER OFF ${STATIC_SCRIPT_MODULES})

list(REMOVE_DUPLICATES SCRIPT_MODULE_PRIVATE_SCRIPTLOADER)

add_library(scripts STATIC
  ScriptLoader.h
  ${SCRIPT_MODULE_PRIVATE_SCRIPTLOADER}
  ${PRIVATE_SOURCES})

target_link_libraries(scripts
  PRIVATE
    acore-core-interface
  PUBLIC
    game-interface)

target_include_directories(scripts
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR})

set_target_properties(scripts
  PROPERTIES
    FOLDER
      "scripts")

# Generate precompiled header
if(USE_SCRIPTPCH)
  list(APPEND ALL_SCRIPT_PROJECTS scripts ${DYNAMIC_SCRIPT_MODULE_PROJECTS})
  add_cxx_pch("${ALL_SCRIPT_PROJECTS}" ${PRIVATE_PCH_HEADER})
endif()

# Remove all shared libraries in the installl directory which
# are contained in the static library already.
if(DISABLED_SCRIPT_MODULE_PROJECTS)
  install(CODE "
    foreach(SCRIPT_TO_UNINSTALL ${DISABLED_SCRIPT_MODULE_PROJECTS})
      if(EXISTS \"\${SCRIPT_TO_UNINSTALL}\")
        message(STATUS \"Uninstalling: \${SCRIPT_TO_UNINSTALL}\")
        file(REMOVE \"\${SCRIPT_TO_UNINSTALL}\")
      endif()
    endforeach()
  ")
endif()

message("")