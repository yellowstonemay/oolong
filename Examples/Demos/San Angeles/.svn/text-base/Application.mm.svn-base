/*
Oolong Engine for the iPhone / iPod touch
Copyright (c) 2007-2008 Wolfgang Engel  http://code.google.com/p/oolongengine/

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose, 
including commercial applications, and to alter it and redistribute it freely, 
subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>

#include <stdio.h>
#include <sys/time.h>

//#include "Log.h"
#include "App.h"
#include "Mathematics.h"
#include "GraphicsDevice.h"
#include "UI.h"
#include "Macros.h"
#include "Timing.h"
#include "MemoryManager.h"

#include "demo.h"


//#define FIXEDPOINTENABLE

int gAppAlive = 1;

static struct timeval startTime = {0,0};
struct timeval currentTime = {0,0};

CDisplayText * AppDisplayText;
int frames;
float frameRate;

//CTexture * Textures;

bool CShell::InitApplication()
{
	AppDisplayText = new CDisplayText;    
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
		printf("Display text textures loaded");

#ifdef DEBUG
		printf("Debug Build");
#endif

	gettimeofday(&startTime, NULL);
		
	appInit();
	
	appConfigureLightAndMaterial();
		
	return true;
}

bool CShell::QuitApplication()
{
	appDeinit();
	
	AppDisplayText->ReleaseTextures();

	delete AppDisplayText;
	
	return true;
}

bool CShell::UpdateScene()
{
    glEnable(GL_DEPTH_TEST);
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	return true;
}


bool CShell::RenderScene()
{
 	static struct timeval time = {0,0};
 
 	frames++;

	gettimeofday(&currentTime, NULL); // The gettimeofday() function shall obtain the current time, expressed as seconds and microseconds since the 
	                               // Epoch, and store it in the timeval structure pointed to by tp. The resolution of the system clock is unspecified.

    unsigned long TickCount = (unsigned long)((currentTime.tv_sec - startTime.tv_sec) * 1000)
            + (unsigned long)((currentTime.tv_usec - startTime.tv_usec) / 1000);
	appRender(TickCount, 480, 320);

	if (currentTime.tv_usec - time.tv_usec) 
	{
		frameRate = ((float)frames/((currentTime.tv_usec - time.tv_usec) / 1000000.0f));
		AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "fps: %3.2f", frameRate);
		time = currentTime;
		frames = 0;
	}
	
	int NumCalls;
	int NumTriangles;
	int NumVertices;
	GetStats(NumCalls, NumTriangles, NumVertices);
	
	AppDisplayText->DisplayText(0, 10, 0.4f, RGBA(255,255,255,255), "Number of Draw Calls %d", NumCalls);
	AppDisplayText->DisplayText(0, 14, 0.4f, RGBA(255,255,255,255), "Number of Triangles %d", NumTriangles);
	AppDisplayText->DisplayText(0, 18, 0.4f, RGBA(255,255,255,255), "Number of Vertices %d", NumVertices);

	// show text on the display
	AppDisplayText->DisplayDefaultTitle("San Angeles", "", eDisplayTextLogoIMG);

	AppDisplayText->Flush();	

	return true;
}

