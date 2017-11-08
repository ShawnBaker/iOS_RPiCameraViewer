// Copyright © 2016-2017 Shawn Baker using the MIT License.
#ifndef socket_h
#define socket_h

#include <stdio.h>

int openSocket(const char *address, int port, int timeout);
void closeSocket(int fd);
int readSocket(int fd, unsigned char *buffer, int len);

#endif /* socket_h */
