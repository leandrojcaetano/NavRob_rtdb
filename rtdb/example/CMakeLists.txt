add_executable(read read.c)
target_link_libraries(read ${PROJECT_NAME})
add_executable(write write.c)
target_link_libraries(write ${PROJECT_NAME})
