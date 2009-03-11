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

// OpenGL ES headers
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>

//#include "Log.h"
#include "App.h"
#include "Mathematics.h"
#include "GraphicsDevice.h"
#include "UI.h"
#include "Macros.h"
#include "Audio.h"
#include "Pathes.h"
#include "TouchScreen.h"

#include <stdio.h>
#include <sys/time.h>

CDisplayText * AppDisplayText;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

// touch screen values
TouchScreenValues *TouchScreen;


int frames;
float frameRate;

enum {
	kSound_Thrust = 0,
	kSound_Start,
	kSound_Success,
	kSound_Failure,
	kNumSounds
};

UInt32 Sounds[kNumSounds];
OSStatus IsSoundRunning[kNumSounds];


bool CShell::InitApplication()
{
	AppDisplayText = new CDisplayText;  
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
		printf("Display text textures loaded\n");
	
	// Setup sound engine. Run it at 44Khz to match the sound files
	SoundEngine_Initialize(44100);
	
	SoundEngine_SetListenerPosition(0.0, 0.0, 0.0f);
	
	// keeps the file name
	char *filename = (char*)malloc(2048 * sizeof(char));
	memset(filename, 0, 2048 * sizeof(char));

	// keeps the path to the sound data
	char *buffer = (char*) malloc(2048 * sizeof(char));
	memset(buffer, 0, 2048 * sizeof(char));
	
	GetResourcePathASCII(buffer, 2048);
	
	// Load each of the four sounds used here
	sprintf(filename, "%s/Start.caf", buffer);
	if(SoundEngine_LoadEffect(filename, &Sounds[kSound_Start]))
		printf("**ERROR** Failed to load sound file.\n");
	sprintf(filename, "%s/Success.caf", buffer);
	if(SoundEngine_LoadEffect(filename, &Sounds[kSound_Success]))
		printf("**ERROR** Failed to load sound file.\n");
	sprintf(filename, "%s/Failure.caf", buffer);
	if(SoundEngine_LoadEffect(filename, &Sounds[kSound_Failure]))
		printf("**ERROR** Failed to load sound file.\n");
	sprintf(filename, "%s/Thrust.caf", buffer);
	if(SoundEngine_LoadLoopingEffect(filename, NULL, NULL, &Sounds[kSound_Thrust]))
		printf("**ERROR** Failed to load sound file.\n");
	
	free(buffer);
	free(filename);
	
	IsSoundRunning[kSound_Thrust] = true;
	SoundEngine_StartEffect( Sounds[kSound_Thrust]);
	
	
	return true;
}

bool CShell::QuitApplication()
{
	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;
	
	// shuts down the sound engine
	SoundEngine_Teardown();	
	
	return true;
}

bool CShell::UpdateScene()
{
    glEnable(GL_DEPTH_TEST);
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// Set the OpenGL projection matrix
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	MATRIX	MyPerspMatrix;
	MatrixPerspectiveFovRH(MyPerspMatrix, f2vt(70), f2vt(((float) 320 / (float) 480)), f2vt(0.1f), f2vt(1000.0f), 0);
	glMultMatrixf(MyPerspMatrix.f);
	
	// do all the timing
	static CFTimeInterval	startTime = 0;
	CFTimeInterval			TimeInterval;
	
	// calculate our local time
	TimeInterval = CFAbsoluteTimeGetCurrent();
	if(startTime == 0)
		startTime = TimeInterval;
	TimeInterval = TimeInterval - startTime;
	
	frames++;
	if (TimeInterval) 
		frameRate = ((float)frames/(TimeInterval));
	
	AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "fps: %3.2f", frameRate);
/*	
    glEnable(GL_DEPTH_TEST);
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	//Set the OpenGL projection matrix
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	MATRIX	MyPerspMatrix;
	MatrixPerspectiveFovRH(MyPerspMatrix, f2vt(70), f2vt(((float) 320 / (float) 480)), f2vt(0.1f), f2vt(1000.0f), 0);
	myglMultMatrix(MyPerspMatrix.f);
	
	static CFTimeInterval	startTime = 0;
	CFTimeInterval			time;
	
	//Calculate our local time
	time = CFAbsoluteTimeGetCurrent();
	if(startTime == 0)
		startTime = time;
	time = time - startTime;
*/	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(0.0, 0.0, - 10.0f);
	glRotatef(50.0f * fmod(TimeInterval, 360.0), 0.0, 1.0, 1.0);
	
	//Start or stop thurst sound & update its position
	//	SoundEngine_Vibrate();
	//	if(thrust && !_lastThrust)
	//		SoundEngine_StartEffect( _sounds[kSound_Thrust]);
	//	else if(!thrust && _lastThrust)
	//		SoundEngine_StopEffect(_sounds[kSound_Thrust], false);
	//	if(thrust)
	
	//SoundEngine_SetEffectPosition(Sounds[kSound_Thrust], 50.0f * fmod(time, 360.0), 0.0, 0.0);
	
	//
	// Touch screen support
	//
	// touch screen coordinates go from 0, 0 in the upper left corner to
	// 320, 480 in the lower right corner
	TouchScreen = GetValuesTouchScreen();
	
	// someone touched the screen ...
	if(TouchScreen->TouchesEnd == false)
	{
		// upper right corner .. box is 40 x 40
		if(TouchScreen->LocationXTouchesBegan <= 40 && TouchScreen->LocationYTouchesBegan <= 40)
		{
			if(IsSoundRunning[kSound_Thrust])
			{
				IsSoundRunning[kSound_Thrust] = false;
				SoundEngine_StopEffect(Sounds[kSound_Thrust], false);
			}
		}
		
		// lower right corner .. box is 40 x 40
		if(TouchScreen->LocationXTouchesBegan >= 280 && TouchScreen->LocationYTouchesBegan >= 440)
		{
			if(!IsSoundRunning[kSound_Thrust])
			{
				SoundEngine_StartEffect(Sounds[kSound_Thrust]);
				IsSoundRunning[kSound_Thrust] = true;
			}
		}
		
		// go to the right
		if(TouchScreen->LocationXTouchesBegan >= 280 && TouchScreen->LocationYTouchesBegan <=40)
		{
			if(IsSoundRunning[kSound_Thrust])
				SoundEngine_SetEffectPosition(Sounds[kSound_Thrust], 2.0 * (TouchScreen->LocationXTouchesBegan / 320) - 1.0, 0.0, 0.0);
		}
		
		// go to the right
		if(TouchScreen->LocationXTouchesBegan <=40 && TouchScreen->LocationYTouchesBegan >=440)
		{
			if(IsSoundRunning[kSound_Thrust])
				SoundEngine_SetEffectPosition(Sounds[kSound_Thrust], 2.0 * (TouchScreen->LocationXTouchesBegan / 320) - 1.0, 0.0, 0.0);
		}
		
		// if center reset everything and vibrate if it is a iPhone
		if(TouchScreen->LocationXTouchesBegan >= 140 &&  
		   TouchScreen->LocationXTouchesBegan <= 180 && 
		   TouchScreen->LocationYTouchesBegan >= 220 && 
		   TouchScreen->LocationYTouchesBegan <= 260)
		{
			if(IsSoundRunning[kSound_Thrust])
			{
#if TARGET_OS_IPHONE
				SoundEngine_Vibrate();
#endif
				SoundEngine_SetEffectPosition(Sounds[kSound_Thrust], 0.0, 0.0, 0.0);
			}
		}
		
		AppDisplayText->DisplayText(0, 18, 0.4f, RGBA(255,255,255,255), "touchesBegan: X: %3.2f Y: %3.2f Count: %3.2f Tab Count %3.2f", 
									TouchScreen->LocationXTouchesBegan, TouchScreen->LocationYTouchesBegan, TouchScreen->CountTouchesBegan, TouchScreen->TapCountTouchesBegan);
		AppDisplayText->DisplayText(0, 22, 0.4f, RGBA(255,255,255,255), "touchesMoved: X: %3.2f Y: %3.2f Count: %3.2f Tab Count %3.2f", 
									TouchScreen->LocationXTouchesMoved, TouchScreen->LocationYTouchesMoved, TouchScreen->CountTouchesMoved, TouchScreen->TapCountTouchesMoved);
	}
	AppDisplayText->DisplayText(0, 10, 0.4f, RGBA(255,255,255,255), "Upper right corner/Lower left corner: Sound off/on");
	AppDisplayText->DisplayText(0, 14, 0.4f, RGBA(255,255,255,255), "Lower right corner/Upper left corner/Center: Sound right/left/center");
	
	return true;
}


bool CShell::RenderScene()
{
    const float verts[] =
    {
         1.0f, 1.0f,-1.0f,	
        -1.0f, 1.0f,-1.0f,	
        -1.0f, 1.0f, 1.0f,	
         1.0f, 1.0f, 1.0f,	

         1.0f,-1.0f, 1.0f,	
        -1.0f,-1.0f, 1.0f,	
        -1.0f,-1.0f,-1.0f,	
         1.0f,-1.0f,-1.0f,	

         1.0f, 1.0f, 1.0f,	
        -1.0f, 1.0f, 1.0f,	
        -1.0f,-1.0f, 1.0f,	
         1.0f,-1.0f, 1.0f,	

         1.0f,-1.0f,-1.0f,	
        -1.0f,-1.0f,-1.0f,	
        -1.0f, 1.0f,-1.0f,	
         1.0f, 1.0f,-1.0f,	

         1.0f, 1.0f,-1.0f,	
         1.0f, 1.0f, 1.0f,	
         1.0f,-1.0f, 1.0f,	
         1.0f,-1.0f,-1.0f,

        -1.0f, 1.0f, 1.0f,	
        -1.0f, 1.0f,-1.0f,	
        -1.0f,-1.0f,-1.0f,	
        -1.0f,-1.0f, 1.0f
     };

    glEnableClientState(GL_VERTEX_ARRAY);
    
    glColor4f(0, 1, 0, 1);
    glVertexPointer(3, GL_FLOAT, 0, verts);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glColor4f(1, 0, 1, 1);
    glVertexPointer(3, GL_FLOAT, 0, verts + 12);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glColor4f(0, 0, 1, 1);
    glVertexPointer(3, GL_FLOAT, 0, verts + 24);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glColor4f(1, 1, 0, 1);
    glVertexPointer(3, GL_FLOAT, 0, verts + 36);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glColor4f(1, 0, 0, 1);
    glVertexPointer(3, GL_FLOAT, 0, verts + 48);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glColor4f(0, 1, 1, 1);
    glVertexPointer(3, GL_FLOAT, 0, verts + 60);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	
	//Start or stop thurst sound & update its position
//	SoundEngine_Vibrate();
//	if(thrust && !_lastThrust)
//		SoundEngine_StartEffect( _sounds[kSound_Thrust]);
//	else if(!thrust && _lastThrust)
//		SoundEngine_StopEffect(_sounds[kSound_Thrust], false);
//	if(thrust)
//		SoundEngine_SetEffectPosition(_sounds[kSound_Thrust], 2.0 * (_position.x / bounds.size.width) - 1.0, 0.0, 0.0);
	
	
	// show text on the display
	AppDisplayText->DisplayDefaultTitle("Load wav audio file", "", eDisplayTextLogoIMG);
	
	AppDisplayText->Flush();	
	
	return true;
}

