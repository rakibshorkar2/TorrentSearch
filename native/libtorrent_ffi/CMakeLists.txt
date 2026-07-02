cmake_minimum_required(VERSION 3.20)
project(torrent_ffi VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# libtorrent library
add_subdirectory(libtorrent)

set(SOURCES
  src/torrent_ffi.cpp
)

set(PUBLIC_HEADERS
  include/torrent_ffi.h
)

add_library(torrent_ffi STATIC ${SOURCES} ${PUBLIC_HEADERS})

target_include_directories(torrent_ffi
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(torrent_ffi PUBLIC torrent libtorrent)

if(IOS)
  set_target_properties(torrent_ffi PROPERTIES
    XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
    XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH "YES"
  )
endif()

install(TARGETS torrent_ffi
  ARCHIVE DESTINATION lib
)
