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
/*
 This example uses art assets from the PowerVR SDK. Imagination Technologies / PowerVR allowed us to use those art assets and we are thankful for this. 
 Having art assets that are optimized for the underlying hardware allows us to show off the capabilties of the graphics chip better.
*/

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>

//#include "Log.h"
#include "App.h"
#include "Mathematics.h"
#include "GraphicsDevice.h"
#include "MemoryManager.h"
#include "UI.h"
#include "Macros.h"
#include "Timing.h"

#include <stdio.h>
#include <sys/time.h>



// textures
#include "Media/crate.h"
#include "Media/stamp.h"
#include "Media/stampnm.h"

GLuint m_ui32Crate;
GLuint m_ui32Stamp;
GLuint m_ui32Stampnm;

VERTTYPE m_fAngle;

/* A structure that contains the information on the cube*/
struct SCube
{
	unsigned short ui16Faces[36];
	VECTOR3 fvVertices[24];
	VERTTYPE fUVs[48];
};

/* Cube data */
SCube m_sCube;

// allocate in heap
CDisplayText * AppDisplayText;
CTexture * Textures;

int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

int frames;
float frameRate;

bool CShell::InitApplication()
{
//	LOGFUNC("InitApplication()");
	
	AppDisplayText = new CDisplayText;  
	Textures = new CTexture;
	
	m_ui32Crate = 0;
	
	m_fAngle = f2vt(0.0f);
	
	/*
		Setup the cubes fave values
	*/
	m_sCube.ui16Faces[0]  = 0;  m_sCube.ui16Faces[1]  = 1;  m_sCube.ui16Faces[2]  = 2;
	m_sCube.ui16Faces[3]  = 2;  m_sCube.ui16Faces[4]  = 3;  m_sCube.ui16Faces[5]  = 0;
	m_sCube.ui16Faces[6]  = 4;  m_sCube.ui16Faces[7]  = 5;  m_sCube.ui16Faces[8]  = 6;
	m_sCube.ui16Faces[9]  = 6;  m_sCube.ui16Faces[10] = 7;  m_sCube.ui16Faces[11] = 4;
	m_sCube.ui16Faces[12] = 8;  m_sCube.ui16Faces[13] = 9;  m_sCube.ui16Faces[14] = 10;
	m_sCube.ui16Faces[15] = 10; m_sCube.ui16Faces[16] = 11; m_sCube.ui16Faces[17] = 8;
	m_sCube.ui16Faces[18] = 12; m_sCube.ui16Faces[19] = 13; m_sCube.ui16Faces[20] = 14;
	m_sCube.ui16Faces[21] = 14; m_sCube.ui16Faces[22] = 15; m_sCube.ui16Faces[23] = 12;
	m_sCube.ui16Faces[24] = 16; m_sCube.ui16Faces[25] = 17; m_sCube.ui16Faces[26] = 18;
	m_sCube.ui16Faces[27] = 18; m_sCube.ui16Faces[28] = 19; m_sCube.ui16Faces[29] = 16;
	m_sCube.ui16Faces[30] = 20; m_sCube.ui16Faces[31] = 21; m_sCube.ui16Faces[32] = 22;
	m_sCube.ui16Faces[33] = 22; m_sCube.ui16Faces[34] = 23; m_sCube.ui16Faces[35] = 20;

	/*
		Initialise the vertices
	*/
	m_sCube.fvVertices[0].x  = f2vt(-1); m_sCube.fvVertices[0].y  = f2vt(-1); m_sCube.fvVertices[0].z  = f2vt(1) ;
	m_sCube.fvVertices[1].x  = f2vt(-1); m_sCube.fvVertices[1].y  = f2vt(-1); m_sCube.fvVertices[1].z  = f2vt(-1);
	m_sCube.fvVertices[2].x  = f2vt(1) ; m_sCube.fvVertices[2].y  = f2vt(-1); m_sCube.fvVertices[2].z  = f2vt(-1);
	m_sCube.fvVertices[3].x  = f2vt(1) ; m_sCube.fvVertices[3].y  = f2vt(-1); m_sCube.fvVertices[3].z  = f2vt(1) ;
	m_sCube.fvVertices[4].x  = f2vt(-1); m_sCube.fvVertices[4].y  = f2vt(1) ; m_sCube.fvVertices[4].z  = f2vt(1) ;
	m_sCube.fvVertices[5].x  = f2vt(1) ; m_sCube.fvVertices[5].y  = f2vt(1) ; m_sCube.fvVertices[5].z  = f2vt(1) ;
	m_sCube.fvVertices[6].x  = f2vt(1) ; m_sCube.fvVertices[6].y  = f2vt(1) ; m_sCube.fvVertices[6].z  = f2vt(-1);
	m_sCube.fvVertices[7].x  = f2vt(-1); m_sCube.fvVertices[7].y  = f2vt(1) ; m_sCube.fvVertices[7].z  = f2vt(-1);
	m_sCube.fvVertices[8].x  = f2vt(-1); m_sCube.fvVertices[8].y  = f2vt(-1); m_sCube.fvVertices[8].z  = f2vt(1) ;
	m_sCube.fvVertices[9].x  = f2vt(1) ; m_sCube.fvVertices[9].y  = f2vt(-1); m_sCube.fvVertices[9].z  = f2vt(1) ;
	m_sCube.fvVertices[10].x = f2vt(1) ; m_sCube.fvVertices[10].y = f2vt(1) ; m_sCube.fvVertices[10].z = f2vt(1) ;
	m_sCube.fvVertices[11].x = f2vt(-1); m_sCube.fvVertices[11].y = f2vt(1) ; m_sCube.fvVertices[11].z = f2vt(1) ;
	m_sCube.fvVertices[12].x = f2vt(1) ; m_sCube.fvVertices[12].y = f2vt(-1); m_sCube.fvVertices[12].z = f2vt(1) ;
	m_sCube.fvVertices[13].x = f2vt(1) ; m_sCube.fvVertices[13].y = f2vt(-1); m_sCube.fvVertices[13].z = f2vt(-1);
	m_sCube.fvVertices[14].x = f2vt(1) ; m_sCube.fvVertices[14].y = f2vt(1) ; m_sCube.fvVertices[14].z = f2vt(-1);
	m_sCube.fvVertices[15].x = f2vt(1) ; m_sCube.fvVertices[15].y = f2vt(1) ; m_sCube.fvVertices[15].z = f2vt(1) ;
	m_sCube.fvVertices[16].x = f2vt(1) ; m_sCube.fvVertices[16].y = f2vt(-1); m_sCube.fvVertices[16].z = f2vt(-1);
	m_sCube.fvVertices[17].x = f2vt(-1); m_sCube.fvVertices[17].y = f2vt(-1); m_sCube.fvVertices[17].z = f2vt(-1);
	m_sCube.fvVertices[18].x = f2vt(-1); m_sCube.fvVertices[18].y = f2vt(1) ; m_sCube.fvVertices[18].z = f2vt(-1);
	m_sCube.fvVertices[19].x = f2vt(1) ; m_sCube.fvVertices[19].y = f2vt(1) ; m_sCube.fvVertices[19].z = f2vt(-1);
	m_sCube.fvVertices[20].x = f2vt(-1); m_sCube.fvVertices[20].y = f2vt(-1); m_sCube.fvVertices[20].z = f2vt(-1);
	m_sCube.fvVertices[21].x = f2vt(-1); m_sCube.fvVertices[21].y = f2vt(-1); m_sCube.fvVertices[21].z = f2vt(1) ;
	m_sCube.fvVertices[22].x = f2vt(-1); m_sCube.fvVertices[22].y = f2vt(1) ; m_sCube.fvVertices[22].z = f2vt(1) ;
	m_sCube.fvVertices[23].x = f2vt(-1); m_sCube.fvVertices[23].y = f2vt(1) ; m_sCube.fvVertices[23].z = f2vt(-1);

	/*
		Initialise the uv coordinates. We're going to use the same coordinates for both
		textures so we only require one set.
	*/
	m_sCube.fUVs[0]  = f2vt(1); m_sCube.fUVs[1]  = f2vt(0);
	m_sCube.fUVs[2]  = f2vt(1); m_sCube.fUVs[3]  = f2vt(1);
	m_sCube.fUVs[4]  = f2vt(0); m_sCube.fUVs[5]  = f2vt(1);
	m_sCube.fUVs[6]  = f2vt(0); m_sCube.fUVs[7]  = f2vt(0);
	m_sCube.fUVs[8]  = f2vt(0); m_sCube.fUVs[9]  = f2vt(0);
	m_sCube.fUVs[10] = f2vt(1); m_sCube.fUVs[11] = f2vt(0);
	m_sCube.fUVs[12] = f2vt(1); m_sCube.fUVs[13] = f2vt(1);
	m_sCube.fUVs[14] = f2vt(0); m_sCube.fUVs[15] = f2vt(1);
	m_sCube.fUVs[16] = f2vt(0); m_sCube.fUVs[17] = f2vt(0);
	m_sCube.fUVs[18] = f2vt(1); m_sCube.fUVs[19] = f2vt(0);
	m_sCube.fUVs[20] = f2vt(1); m_sCube.fUVs[21] = f2vt(1);
	m_sCube.fUVs[22] = f2vt(0); m_sCube.fUVs[23] = f2vt(1);
	m_sCube.fUVs[24] = f2vt(0); m_sCube.fUVs[25] = f2vt(0);
	m_sCube.fUVs[26] = f2vt(1); m_sCube.fUVs[27] = f2vt(0);
	m_sCube.fUVs[28] = f2vt(1); m_sCube.fUVs[29] = f2vt(1);
	m_sCube.fUVs[30] = f2vt(0); m_sCube.fUVs[31] = f2vt(1);
	m_sCube.fUVs[32] = f2vt(0); m_sCube.fUVs[33] = f2vt(0);
	m_sCube.fUVs[34] = f2vt(1); m_sCube.fUVs[35] = f2vt(0);
	m_sCube.fUVs[36] = f2vt(1); m_sCube.fUVs[37] = f2vt(1);
	m_sCube.fUVs[38] = f2vt(0); m_sCube.fUVs[39] = f2vt(1);
	m_sCube.fUVs[40] = f2vt(0); m_sCube.fUVs[41] = f2vt(0);
	m_sCube.fUVs[42] = f2vt(1); m_sCube.fUVs[43] = f2vt(0);
	m_sCube.fUVs[44] = f2vt(1); m_sCube.fUVs[45] = f2vt(1);
	m_sCube.fUVs[46] = f2vt(0); m_sCube.fUVs[47] = f2vt(1);
	
	// load the crate texture
  	if(Textures->LoadTextureFromPointer((void*)crate, &m_ui32Crate))
		printf("Crate texture loaded");
		
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	// load the red stamp texture
  	if(Textures->LoadTextureFromPointer((void*)stamp, &m_ui32Stamp))
		printf("Red stamp texture loaded");
		
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	// load the red stamp normal map texture
  	if(Textures->LoadTextureFromPointer((void*)stampnm, &m_ui32Stampnm))
		printf("Normal map for red stamp texture loaded");
		
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
		printf("Display text textures loaded");
		
#ifdef DEBUG
		printf("Debug Build", Logger::LOG_DATA);
#endif
	
	return true;
}

bool CShell::QuitApplication()
{
	Textures->ReleaseTexture(m_ui32Crate);
	Textures->ReleaseTexture(m_ui32Crate);
	Textures->ReleaseTexture(m_ui32Stampnm);
	
	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;
	delete Textures;

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
	
	++frames;
	
	CFTimeInterval			TimeInterval;
	
	frameRate = GetFps(frames, TimeInterval);
	
	AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "fps: %3.2f", frameRate);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(0.0, 0.0, - 10.0f);
	glRotatef(50.0f * fmod(TimeInterval, 360.0), 0.0, 1.0, 1.0);
	
	return true;
}


bool CShell::RenderScene()
{
	/* Set vertex data */
	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(3, VERTTYPEENUM, sizeof(VECTOR3), &m_sCube.fvVertices[0]);

	/* Set texture data */

	/*Set the texture data for the first texture.*/
	glClientActiveTexture(GL_TEXTURE0);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glTexCoordPointer(2, VERTTYPEENUM, sizeof(float) * 2, &m_sCube.fUVs[0]);

	/*
		Set the texture for the second texture. In this case we are just reusing the first
		set of texture coordinates.
	*/
	glClientActiveTexture(GL_TEXTURE1);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glTexCoordPointer(2, VERTTYPEENUM, sizeof(float) * 2, &m_sCube.fUVs[0]);

	/* Enable 2D texturing for the first texture. */
	glActiveTexture(GL_TEXTURE0);
	glEnable(GL_TEXTURE_2D);

	/* Enable 2D texturing for the second texture. */
	glActiveTexture(GL_TEXTURE1);
	glEnable(GL_TEXTURE_2D);

	/*
		The Dot3 example will be different to the other ones as it 
		will use a normal map and a light vector.
	*/
	VECTOR3 fLightVector;
	
	// move the light vector around the cube
	++m_fAngle;

	if(m_fAngle > f2vt(360.0f))
		m_fAngle = f2vt(0.0f);

	/*
		Set up the light vector and rotate it round the cube.
	*/
	fLightVector.x = sin(f2vt(m_fAngle * (PIf / 180.0f)));
	fLightVector.y = f2vt(0.0f);
	fLightVector.z = cos(f2vt(m_fAngle * (PIf / 180.0f)));

	/* Half shifting to have a value between 0.0f and 1.0f */
	fLightVector.x = VERTTYPEMUL(fLightVector.x, f2vt(0.5f)) + f2vt(0.5f);
	fLightVector.y = VERTTYPEMUL(fLightVector.y, f2vt(0.5f)) + f2vt(0.5f);
	fLightVector.z = VERTTYPEMUL(fLightVector.z, f2vt(0.5f)) + f2vt(0.5f);

	/* Set light direction as a colour
	 * (the colour ordering depend on how the normal map has been computed)
	 * red=y, green=z, blue=x */
	glColor4f(fLightVector.y, fLightVector.z, fLightVector.x, 0);

	/* 
		Set up the First Texture (the normal map) and combine it with the texture
		colour that we've set.
	*/
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, m_ui32Stampnm);

	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_DOT3_RGBA);
	glTexEnvf(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_TEXTURE);
	glTexEnvf(GL_TEXTURE_ENV, GL_SOURCE1_RGB, GL_PREVIOUS);

	/* Set up the Second Texture and combine it with the result of the Dot3 combination*/
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, m_ui32Crate);

	/* Set the texture environment mode for this texture to combine */
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);

	/* Set the method we're going to combine the two textures by. */
	glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);

	/* Use the previous combine texture as source 0*/
	glTexEnvf(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_TEXTURE);

	/* Use the current texture as source 1 */
	glTexEnvf(GL_TEXTURE_ENV, GL_SOURCE1_RGB, GL_PREVIOUS);

	/*
		Set what we will operate on, in this case we are going to use
		just the texture colours.
	*/
	glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
	glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);

	/* Draw mesh */
	glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, &m_sCube.ui16Faces[0]);
	
	// show text on the display
	AppDisplayText->DisplayDefaultTitle("Per-Pixel Lighting", "", eDisplayTextLogoIMG);


	// Reset
	glColor4f(f2vt(1.0),f2vt(1.0),f2vt(1.0),f2vt(1.0));

	/* Disable states */
	/*Disable the vertex buffer. */
	glDisableClientState(GL_VERTEX_ARRAY);

	/*Disable the buffer for the first set of texture coordinates*/
	glClientActiveTexture(GL_TEXTURE0);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);

	/*Disable the buffer for the second set of texture coordinates*/
	glClientActiveTexture(GL_TEXTURE1);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);

	/* Disable 2D texturing for the first texture */
	glActiveTexture(GL_TEXTURE0);
	glDisable(GL_TEXTURE_2D);

	/* Disable 2D texturing for the second texture */
	glActiveTexture(GL_TEXTURE1);
	glDisable(GL_TEXTURE_2D);
	
	AppDisplayText->Flush();	
	
	return true;
}

