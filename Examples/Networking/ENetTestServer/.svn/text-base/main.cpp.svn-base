/*
 Oolong Engine for the iPhone / iPod touch
 Copyright (c) 2007-2008 Wolfgang Engel  http://code.google.com/p/oolongengine/
 
 Author: Joe Woynillowicz
 
 This software is provided 'as-is', without any express or implied warranty.
 In no event will the authors be held liable for any damages arising from the use of this software.
 Permission is granted to anyone to use this software for any purpose, 
 including commercial applications, and to alter it and redistribute it freely, 
 subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
 */

#include <iostream>
#include "enet.h"

int main (int argc, char * const argv[]) {
    
    if(enet_initialize() != 0)
	{
		printf("An error occurred while initializing ENet.\n");
	}
	
	ENetAddress address;
	ENetHost* server;
	
	address.host = ENET_HOST_ANY;
	address.port = 9050;
	
	// up to 32 clients with unlimited bandwidth
	server = enet_host_create(&address, 32, 0, 0);
	if(server == NULL)
	{
		printf("An error occurred while trying to create an ENet server host.\n");
	}
	
	int clients = 0;
	
	// server main loop
	while(true)
	{
		ENetEvent event;
		while(enet_host_service(server, &event, 1000) > 0)
		{
			switch(event.type)
			{
				case ENET_EVENT_TYPE_CONNECT:
					printf ("A new client connected from %x:%u.\n", 
							event.peer -> address.host,
							event.peer -> address.port);
					
					clients++;
					
					break;
					
				case ENET_EVENT_TYPE_RECEIVE:
					printf ("A packet of length %u containing %s was received.\n",
							event.packet->dataLength,
							event.packet->data);
					
					ENetPacket* packet = enet_packet_create(event.packet->data, event.packet->dataLength, ENET_PACKET_FLAG_RELIABLE);
					enet_host_broadcast(server, 0, packet);
					enet_host_flush(server);
					
					enet_packet_destroy(event.packet);
					break;
					
				case ENET_EVENT_TYPE_DISCONNECT:
					printf("Client disconnected.\n");
					event.peer->data = NULL;
			}
		}
	}
	
	return 0;
}

