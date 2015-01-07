find_package( Threads )
add_executable(comm multicast.c comm.c)
target_link_libraries(comm ${CMAKE_THREAD_LIBS_INIT} ${PROJECT_NAME})
