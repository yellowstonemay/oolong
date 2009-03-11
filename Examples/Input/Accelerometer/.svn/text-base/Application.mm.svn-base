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

#import "EAGLView.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>

#include "App.h"
//#include "Camera.h"
#include "Mathematics.h"
#include "Accelerometer.h"
#include "GraphicsDevice.h"
#include "UI.h"
#include "Macros.h"

#include <stdio.h>
#include <sys/time.h>
#import "Media/teapot.h"

//#include <stdio.h>

#define kTeapotScale				3.0

#define kAccelerometerFrequency		30.0 //Hz
#define kFilteringFactor			0.1

CDisplayText * AppDisplayText;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

int frames;
float frameRate;


//#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)

Accel* gAccel;


bool CShell::InitApplication()
{
	gAccel = [Accel alloc];
	
	[gAccel SetupAccelerometer: kAccelerometerFrequency];

//	CGRect					rect = [[UIScreen mainScreen] bounds];
	const GLfloat			lightAmbient[] = {0.2, 0.2, 0.2, 1.0};
	const GLfloat			lightDiffuse[] = {1.0, 0.6, 0.0, 1.0};
	const GLfloat			matAmbient[] = {0.6, 0.6, 0.6, 1.0};
	const GLfloat			matDiffuse[] = {1.0, 1.0, 1.0, 1.0};	
	const GLfloat			matSpecular[] = {1.0, 1.0, 1.0, 1.0};
	const GLfloat			lightPosition[] = {0.0, 0.0, 1.0, 0.0}; 
	const GLfloat			lightShininess = 100.0;
	GLfloat					zNear = 0.1,
							zFar = 1000.0,
							fieldOfView = 60.0;
	GLfloat					size = 0;
	//Configure OpenGL lighting
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, matAmbient);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, matDiffuse);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, matSpecular);
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, lightShininess);
	glLightfv(GL_LIGHT0, GL_AMBIENT, lightAmbient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, lightDiffuse);
	glLightfv(GL_LIGHT0, GL_POSITION, lightPosition); 			
	glShadeModel(GL_SMOOTH);
	
//	glMatrixMode(GL_PROJECTION);
//	glLoadIdentity();
	
	//Set the OpenGL projection matrix
	glMatrixMode(GL_PROJECTION);
	size = zNear * tanf(DEGREES_TO_RADIANS(fieldOfView) / 2.0);
	glFrustumf(-size, size, -size / (320.0f / 480.0f), size / (320.0f / 480.0f), zNear, zFar);
	
	AppDisplayText = new CDisplayText;  
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
		printf("Display text textures loaded\n");

	return true;
}

bool CShell::QuitApplication()
{
	[gAccel release];

	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;

	return true;
}

bool CShell::UpdateScene()
{
    glEnable(GL_DEPTH_TEST);
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	
	
	//Make the OpenGL modelview matrix the default
	glMatrixMode(GL_MODELVIEW);
	
	// Setup model view matrix
	glLoadIdentity();
	glTranslatef(0.0, -0.1, -1.0);
	glScalef(kTeapotScale, kTeapotScale, kTeapotScale);
	
	GLfloat	matrix[16];
	[gAccel GetAccelerometerMatrix:(GLfloat *) matrix];
	
	// Finally load matrix
	glMultMatrixf((GLfloat*)matrix);
	
	// rotate teapot
	glRotatef(90.0, 0.0, 0.0, 1.0);
	
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

	return true;
}


bool CShell::RenderScene()
{
	int start = 0, i = 0;
	
	// if I call this in UpdateScene it does not work ..
	double AccelerometerVector[3];
	[gAccel GetAccelerometerVector:(double *) AccelerometerVector];
	
	AppDisplayText->DisplayText(0, 12, 0.4f, RGBA(255,255,255,255), "Accelerometer Vector: %3.2f, %3.2f, %3.2f", AccelerometerVector[0], AccelerometerVector[1], AccelerometerVector[2]);
	
	//Configure OpenGL arrays
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glVertexPointer(3, GL_FLOAT, 0, teapot_vertices);
	glNormalPointer(GL_FLOAT, 0, teapot_normals);
	glEnable(GL_NORMALIZE);
							
	while(i < num_teapot_indices) 
	{
		if(teapot_indices[i] == -1) 
		{
			glDrawElements(GL_TRIANGLE_STRIP, i - start, GL_UNSIGNED_SHORT, &teapot_indices[start]);
			start = i + 1;
		}
		i++;
	}
		
	if(start < num_teapot_indices)
		glDrawElements(GL_TRIANGLE_STRIP, i - start - 1, GL_UNSIGNED_SHORT, &teapot_indices[start]);
		
	// show text on the display
	AppDisplayText->DisplayDefaultTitle("Accelerometer Support", "", eDisplayTextLogoIMG);
	
	AppDisplayText->Flush();	


	return true;
}

