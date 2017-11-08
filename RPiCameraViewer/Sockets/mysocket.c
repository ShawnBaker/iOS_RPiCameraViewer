// Copyright © 2016-2017 Shawn Baker using the MIT License.
#include <sys/socket.h>
#include <sys/fcntl.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include "mysocket.h"

//**********************************************************************
// openSocket
//**********************************************************************
int openSocket(const char *address, int port, int timeout)
{
	struct sockaddr_in serv_addr;
	fd_set fdset;
	struct timeval tv;
	
	// set the connection parameters
	memset(&serv_addr, '0', sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_port = htons(port);
	if (inet_pton(AF_INET, address, &serv_addr.sin_addr) <= 0)
	{
		return -1;
	}
	
	// open the socket and make it non-blocking
	int fd = socket(AF_INET, SOCK_STREAM, 0);
	if (fd < 0)
	{
		return -2;
	}
	int flags = fcntl(fd, F_GETFL, 0);
	fcntl(fd, F_SETFL, flags | O_NONBLOCK);
	
	// connect the socket
	if (connect(fd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0 && errno != EINPROGRESS)
	{
		close(fd);
		return -3;
	}

	// wait for the connect to succeed or timeout
	FD_ZERO(&fdset);
	FD_SET(fd, &fdset);
	tv.tv_sec = 0;
	tv.tv_usec = timeout * 1000;
	if (select(fd + 1, NULL, &fdset, NULL, &tv) <= 0)
	{
		close(fd);
		return -4;
	}
	int err;
	socklen_t errlen = sizeof(err);
	getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &errlen);
	if (err != 0)
	{
		close(fd);
		return -5;
	}
	
	// set the socket back to blocking
	fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);
	
	// return the file
	return fd;
}

//**********************************************************************
// closeSocket
//**********************************************************************
void closeSocket(int fd)
{
	close(fd);
}

//**********************************************************************
// readSocket
//**********************************************************************
int readSocket(int fd, unsigned char *buffer, int len)
{
	int n;
	do
	{
		n = (int)read(fd, buffer, len);
	}
	while (n == -1 && errno == EINTR);
	return n;
}
