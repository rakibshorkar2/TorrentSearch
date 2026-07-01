cmake_minimum_required(VERSION 3.20)
project(torrent_engine VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Sources
set(SOURCES
  src/torrent_engine.cpp
  src/sha1.cpp
  src/bencode.cpp
  src/magnet_uri.cpp
  src/piece_manager.cpp
)

# Headers
set(PUBLIC_HEADERS
  include/torrent_engine.h
)

# Create static library
add_library(torrent_engine STATIC ${SOURCES} ${PUBLIC_HEADERS})

target_include_directories(torrent_engine
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# iOS-specific settings
if(IOS)
  set_target_properties(torrent_engine PROPERTIES
    XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
    XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH "YES"
  )
endif()

# Install
install(TARGETS torrent_engine
  ARCHIVE DESTINATION lib
)
