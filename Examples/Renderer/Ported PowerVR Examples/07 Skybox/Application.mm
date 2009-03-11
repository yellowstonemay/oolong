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

#include "App.h"
#include "Mathematics.h"
#include "GraphicsDevice.h"
#include "UI.h"
#include "Macros.h"
#include "Geometry.h"
#include "MemoryManager.h"
#include "Macros.h"
#include "Pathes.h"

#include <stdio.h>
#include <sys/time.h>

CDisplayText * AppDisplayText;
CTexture * Textures;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

int frames;
float frameRate;

/****************************************************************************
 ** DEFINES                                                                **
 ****************************************************************************/

/* Assuming a 4:3 aspect ratio: */
#define WIDTH 320
#define HEIGHT 480
#define CAM_ASPECT	((float)WIDTH / (float) HEIGHT)
#define CAM_NEAR	(4.0f)
#define CAM_FAR		(5000.0f)

#define SKYBOX_ZOOM			150.0f
#define SKYBOX_ADJUSTUVS	true

#ifndef PI
#define PI 3.14159f
#endif

// OpenGL handles for textures and VBOs
GLuint m_ui32BalloonTex;
GLuint m_ui32SkyboxTex[6];

GLuint*	m_puiVbo;
GLuint*	m_puiIndexVbo;

/* Print3D, Extension and POD Class Objects */
CPVRTModelPOD *m_Scene;

/* View and Projection Matrices */
MATRIX	m_mView, m_mProj;

/* Skybox */
VERTTYPE* g_skyboxVertices;
VERTTYPE* g_skyboxUVs;

/* View Variables */
VERTTYPE m_fViewAngle;
VERTTYPE m_fViewDistance, m_fViewAmplitude, m_fViewAmplitudeAngle;
VERTTYPE m_fViewUpDownAmplitude, m_fViewUpDownAngle;

/* Vectors for calculating the view matrix and saving the camera position*/
VECTOR3 m_fCameraTo, m_fCameraUp, m_fCameraPos;

/****************************************************************************
 ** Function Definitions
 ****************************************************************************/
void CameraGetMatrix();
void ComputeViewMatrix();
void DrawSkybox();
void DrawBalloon();
void CreateSkybox(float scale, bool adjustUV, int textureSize, VERTTYPE** Vertices, VERTTYPE** UVs);
void DestroySkybox(VERTTYPE* Vertices, VERTTYPE* UVs);
void LoadVbos();


bool CShell::InitApplication()
{
	AppDisplayText = new CDisplayText;  
	Textures = new CTexture;
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
		printf("Display text textures loaded\n");

	/* Init values to defaults */
	m_fViewAngle = PIOVERTWO;
	
	m_fViewDistance = f2vt(100.0f);
	m_fViewAmplitude = f2vt(60.0f);
	m_fViewAmplitudeAngle = f2vt(0.0f);
	
	m_fViewUpDownAmplitude = f2vt(50.0f);
	m_fViewUpDownAngle = f2vt(0.0f);
	
        m_puiVbo = 0;
	m_puiIndexVbo = 0;
	
	m_fCameraTo.x = f2vt(0);
	m_fCameraTo.y = f2vt(0);
	m_fCameraTo.z = f2vt(0);
	
	m_fCameraUp.x = f2vt(0);
	m_fCameraUp.y = f2vt(1);
	m_fCameraUp.z = f2vt(0);
	
	m_Scene = (CPVRTModelPOD*)malloc(sizeof(CPVRTModelPOD));

	/*
		Loads the scene from the .pod file into a CPVRTModelPOD object.
		We could also export the scene as a header file and
		load it with ReadFromMemory().
	*/
	char *buffer = new char[2048];
	GetResourcePathASCII(buffer, 2048);

	/* Gets the Data Path */
	char		*filename = new char[2048];
	sprintf(filename, "%s/Balloon_float.pod", buffer);
	if(!m_Scene->ReadFromFile(filename))
	   return false;

	int		i;
	
	/******************************
	 ** Create Textures           **
	 *******************************/
	for (i=0; i<6; i++)
	{
		memset(filename, 0, 2048 * sizeof(char));
		sprintf(filename, "%s/skybox%d.pvr", buffer, (i+1));
		if(!Textures->LoadTextureFromPVR(filename, &m_ui32SkyboxTex[i]))
		{
			printf("**ERROR** Failed to load texture for skybox.\n");
		}
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	}

	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/balloon.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32BalloonTex))
	{
		printf("**ERROR** Failed to load texture for Background.\n");
	}
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	delete [] filename;
	delete [] buffer;
	
	//	Initialize VBO data
	LoadVbos();

	
	/*********************/
	/* Create the skybox */
	/*********************/
	CreateSkybox( SKYBOX_ZOOM, SKYBOX_ADJUSTUVS, 512, &g_skyboxVertices, &g_skyboxUVs );
	
	/**********************
	 ** Projection Matrix **
	 **********************/
	
	/* Projection */
	MatrixPerspectiveFovRH(m_mProj, f2vt(PI / 6), f2vt(CAM_ASPECT), f2vt(CAM_NEAR), f2vt(CAM_FAR), true);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	glMultMatrixf(m_mProj.f);
	
	/******************************
	 ** GENERIC RENDER STATES     **
	 ******************************/
	
	/* The Type Of Depth Test To Do */
	glDepthFunc(GL_LEQUAL);
	
	/* Enables Depth Testing */
	glEnable(GL_DEPTH_TEST);
	
	/* Enables Smooth Color Shading */
	glShadeModel(GL_SMOOTH);
	
	/* Enable texturing */
	glEnable(GL_TEXTURE_2D);
	
	/* Define front faces */
	glFrontFace(GL_CW);

	// Disable Blending
	glDisable(GL_BLEND);
		
	/* Enables texture clamping */
	glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
	glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
	
	/* Sets the clear color */
	glClearColor(f2vt(0.5f), f2vt(0.5f), f2vt(0.5f), 0);
	
	/* Reset the model view matrix to position the light */
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	/* Setup ambiant light */
    glEnable(GL_LIGHTING);
	VERTTYPE lightGlobalAmbient[] = {f2vt(0.4f), f2vt(0.4f), f2vt(0.4f), f2vt(1.0f)};
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lightGlobalAmbient);
	
	/* Setup a directional light source */
	VERTTYPE lightPosition[] = {f2vt(+0.7f), f2vt(+1.0f), f2vt(-0.2f), f2vt(0.0f)};
    VERTTYPE lightAmbient[]  = {f2vt(0.6f), f2vt(0.6f), f2vt(0.6f), f2vt(1.0f)};
    VERTTYPE lightDiffuse[]  = {f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f)};
    VERTTYPE lightSpecular[] = {f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f)};
	
    glEnable(GL_LIGHT0);
    glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
    glLightfv(GL_LIGHT0, GL_AMBIENT, lightAmbient);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, lightDiffuse);
    glLightfv(GL_LIGHT0, GL_SPECULAR, lightSpecular);
	
	/* Setup the balloon material */
	VERTTYPE objectMatAmb[] = {f2vt(0.7f), f2vt(0.7f), f2vt(0.7f), f2vt(1.0f)};
	VERTTYPE objectMatDiff[] = {f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f)};
	VERTTYPE objectMatSpec[] = {f2vt(0.0f), f2vt(0.0f), f2vt(0.0f), f2vt(0.0f)};
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, objectMatAmb);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, objectMatDiff);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, objectMatSpec);
	
	return true;
}

void LoadVbos()
{
	if(!m_puiVbo)
		m_puiVbo = new GLuint[m_Scene->nNumMesh];

	if(!m_puiIndexVbo)
		m_puiIndexVbo = new GLuint[m_Scene->nNumMesh];

	/*
		Load vertex data of all meshes in the scene into VBOs

		The meshes have been exported with the "Interleave Vectors" option,
		so all data is interleaved in the buffer at pMesh->pInterleaved.
		Interleaving data improves the memory access pattern and cache efficiency,
		thus it can be read faster by the hardware.
	*/

	glGenBuffers(m_Scene->nNumMesh, m_puiVbo);

	for(unsigned int i = 0; i < m_Scene->nNumMesh; ++i)
	{
		// Load vertex data into buffer object
		SPODMesh& Mesh = m_Scene->pMesh[i];
		unsigned int uiSize = Mesh.nNumVertex * Mesh.sVertex.nStride;

		glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[i]);
		glBufferData(GL_ARRAY_BUFFER, uiSize, Mesh.pInterleaved, GL_STATIC_DRAW);

		// Load index data into buffer object if available
		m_puiIndexVbo[i] = 0;

		if(Mesh.sFaces.pData)
		{
			glGenBuffers(1, &m_puiIndexVbo[i]);
			uiSize = PVRTModelPODCountIndices(Mesh) * sizeof(GLshort);
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[i]);
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, uiSize, Mesh.sFaces.pData, GL_STATIC_DRAW);
		}
	}

	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}


bool CShell::QuitApplication()
{
	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;
	
	int i;
	
	delete[] m_puiVbo;
	delete[] m_puiIndexVbo;
	
	/* Release all Textures */
	Textures->ReleaseTexture(m_ui32BalloonTex);

		for (i = 0; i < 6; i++)
	{
		Textures->ReleaseTexture(m_ui32SkyboxTex[i]);
	}
	
	/* Destroy the skybox */
	DestroySkybox( g_skyboxVertices, g_skyboxUVs );
	
	delete Textures;
	
	m_Scene->Destroy();

	return true;
}

bool CShell::UpdateScene()
{
    glEnable(GL_DEPTH_TEST);
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
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
	
	AppDisplayText->DisplayText(0, 10, 0.4f, RGBA(255,255,255,255), "fps: %3.2f", frameRate);
	
	return true;
}


bool CShell::RenderScene()
{
	/* Clear the depth and frame buffer */
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	/* Set Z compare properties */
	glEnable(GL_DEPTH_TEST);
	
	/* Disable Blending*/
	glDisable(GL_BLEND);
	
	/* Calculate the model view matrix turning around the balloon */
	ComputeViewMatrix();
	
	// Enable States
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	// Draw the skybox
	DrawSkybox();
	
	// The balloon has normals
	glEnableClientState(GL_NORMAL_ARRAY);

	// Draw the balloon
	DrawBalloon();
	
	// Enable States
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// show text on the display
	AppDisplayText->DisplayDefaultTitle("Skybox", "Skybox with PVRTC", eDisplayTextLogoIMG);
	
	AppDisplayText->Flush();	
	
	return true;
}

/*******************************************************************************
 * Function Name  : ComputeViewMatrix
 * Description    : Calculate the view matrix turning around the balloon
 *******************************************************************************/
void ComputeViewMatrix()
{
	// Calculate the distance to balloon
	VERTTYPE fDistance = m_fViewDistance + VERTTYPEMUL(m_fViewAmplitude, f2vt(sin(m_fViewAmplitudeAngle)));
	fDistance = VERTTYPEMUL(fDistance, f2vt(0.2f));
	m_fViewAmplitudeAngle += 0.004f;
	
	// Calculate the vertical position of the camera
	VERTTYPE fUpdown = VERTTYPEMUL(m_fViewUpDownAmplitude, f2vt(sin(m_fViewUpDownAngle)));
	fUpdown = VERTTYPEMUL(fUpdown, f2vt(0.2f));
	m_fViewUpDownAngle += 0.005f;
	
	// Calculate the angle of the camera around the balloon
	m_fCameraPos.x = VERTTYPEMUL(fDistance, f2vt(cos(m_fViewAngle)));
	m_fCameraPos.y = fUpdown;
	m_fCameraPos.z = VERTTYPEMUL(fDistance, f2vt(sin(m_fViewAngle)));
	
	m_fViewAngle += 0.003f;
	
	/* Compute and set the matrix */
	MatrixLookAtRH(m_mView, m_fCameraPos, m_fCameraTo, m_fCameraUp);
	glMatrixMode(GL_MODELVIEW);
	glLoadMatrixf(m_mView.f);
}

/*******************************************************************************
 * Function Name  : DrawSkybox
 * Description    : Draws the skybox
 *******************************************************************************/
void DrawSkybox()
{
	/* Only use the texture color */
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	
	/* Draw the skybox around the camera position */
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glTranslatef(-m_fCameraPos.x, -m_fCameraPos.y, -m_fCameraPos.z);

	// Disable lighting
	glDisable(GL_LIGHTING);
	
	/* Enable backface culling for skybox; need to ensure skybox faces are set up properly */
	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);
	
	for(int i = 0; i < 6; ++i)
	{
		/* Set Data Pointers */
		glBindTexture(GL_TEXTURE_2D, m_ui32SkyboxTex[i]);
		glVertexPointer(3, VERTTYPEENUM, sizeof(VERTTYPE)*3, &g_skyboxVertices[i*4*3]);
		glTexCoordPointer(2, VERTTYPEENUM, sizeof(VERTTYPE)*2, &g_skyboxUVs[i*4*2]);
		/* Draw */
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	}
	
	glPopMatrix();
}

/*******************************************************************************
 * Function Name  : DrawBalloon
 * Description    : Draws the balloon
 *******************************************************************************/
void DrawBalloon()
{
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	
	MATRIX worldMatrix;
	m_Scene->GetWorldMatrix(worldMatrix, m_Scene->pNode[0]);
	glMultMatrixf(worldMatrix.f);
	
	/* Modulate with vertex color */
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	
	/* Enable lighting */
	glEnable(GL_LIGHTING);
	
	/* Bind the Texture */
	glBindTexture(GL_TEXTURE_2D, m_ui32BalloonTex);
	
	/* Enable back face culling */
	glEnable(GL_CULL_FACE);
	glCullFace(GL_FRONT);
	
	SPODMesh& Mesh = m_Scene->pMesh[0];
	
	// Bind the vertex buffers
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[0]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[0]);
	
	// Setup pointers
	glVertexPointer(3, VERTTYPEENUM, Mesh.sVertex.nStride, Mesh.sVertex.pData);
	glTexCoordPointer(2, VERTTYPEENUM, Mesh.psUVW[0].nStride, Mesh.psUVW[0].pData);
	glNormalPointer(VERTTYPEENUM, Mesh.sNormals.nStride, Mesh.sNormals.pData);
	
	glDrawElements(GL_TRIANGLES, Mesh.nNumFaces * 3, GL_UNSIGNED_SHORT, 0);
	
	// unbind the vertex buffers as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	
	glPopMatrix();
}


/*******************************************************************************
 * Function Name  : CameraGetMatrix
 * Global Used    :
 * Description    : Function to setup camera position
 *
 *******************************************************************************/
void CameraGetMatrix()
{
	VECTOR3	vFrom, vTo, vUp;
	VERTTYPE	fFOV;
	
	vUp.x = f2vt(0.0f);
	vUp.y = f2vt(1.0f);
	vUp.z = f2vt(0.0f);
	
	if(m_Scene->nNumCamera)
	{
		/* Get Camera data from POD Geometry File */
		fFOV = m_Scene->GetCameraPos(vFrom, vTo, 0);
		fFOV = VERTTYPEMUL(fFOV, f2vt(0.75f));		// Convert from horizontal FOV to vertical FOV (0.75 assumes a 4:3 aspect ratio)
	}
	else
	{
		fFOV = f2vt(PI / 6);
	}
	
	/* View */
	MatrixLookAtRH(m_mView, vFrom, vTo, vUp);
	
	/* Projection */
	MatrixPerspectiveFovRH(m_mProj, fFOV, f2vt(CAM_ASPECT), f2vt(CAM_NEAR), f2vt(CAM_FAR), true);
}

/*!***************************************************************************
 @Function			SetVertex
 @Modified			Vertices
 @Input				index
 @Input				x
 @Input				y
 @Input				z
 @Description		Writes a vertex in a vertex array
 *****************************************************************************/
void SetVertex(VERTTYPE** Vertices, int index, VERTTYPE x, VERTTYPE y, VERTTYPE z)
{
	(*Vertices)[index*3+0] = x;
	(*Vertices)[index*3+1] = y;
	(*Vertices)[index*3+2] = z;
}

/*!***************************************************************************
 @Function			SetUV
 @Modified			UVs
 @Input				index
 @Input				u
 @Input				v
 @Description		Writes a texture coordinate in a texture coordinate array
 *****************************************************************************/
void SetUV(VERTTYPE** UVs, int index, VERTTYPE u, VERTTYPE v)
{
	(*UVs)[index*2+0] = u;
	(*UVs)[index*2+1] = v;
}

/*!***************************************************************************
 @Function		PVRTCreateSkybox
 @Input			scale			Scale the skybox
 @Input			adjustUV		Adjust or not UVs for PVRT compression
 @Input			textureSize		Texture size in pixels
 @Output		Vertices		Array of vertices
 @Output		UVs				Array of UVs
 @Description	Creates the vertices and texture coordinates for a skybox
 *****************************************************************************/
void CreateSkybox(float scale, bool adjustUV, int textureSize, VERTTYPE** Vertices, VERTTYPE** UVs)
{
	*Vertices = new VERTTYPE[24*3];
	*UVs = new VERTTYPE[24*2];
	
	VERTTYPE unit = f2vt(1);
	VERTTYPE a0 = 0, a1 = unit;
	
	if (adjustUV)
	{
		VERTTYPE oneover = f2vt(1.0f / textureSize);
		a0 = VERTTYPEMUL(f2vt(4.0f), oneover);
		a1 = unit - a0;
	}
	
	// Front
	SetVertex(Vertices, 0, -unit, +unit, -unit);
	SetVertex(Vertices, 1, +unit, +unit, -unit);
	SetVertex(Vertices, 2, -unit, -unit, -unit);
	SetVertex(Vertices, 3, +unit, -unit, -unit);
	SetUV(UVs, 0, a0, a1);
	SetUV(UVs, 1, a1, a1);
	SetUV(UVs, 2, a0, a0);
	SetUV(UVs, 3, a1, a0);
	
	// Right
	SetVertex(Vertices, 4, +unit, +unit, -unit);
	SetVertex(Vertices, 5, +unit, +unit, +unit);
	SetVertex(Vertices, 6, +unit, -unit, -unit);
	SetVertex(Vertices, 7, +unit, -unit, +unit);
	SetUV(UVs, 4, a0, a1);
	SetUV(UVs, 5, a1, a1);
	SetUV(UVs, 6, a0, a0);
	SetUV(UVs, 7, a1, a0);
	
	// Back
	SetVertex(Vertices, 8 , +unit, +unit, +unit);
	SetVertex(Vertices, 9 , -unit, +unit, +unit);
	SetVertex(Vertices, 10, +unit, -unit, +unit);
	SetVertex(Vertices, 11, -unit, -unit, +unit);
	SetUV(UVs, 8 , a0, a1);
	SetUV(UVs, 9 , a1, a1);
	SetUV(UVs, 10, a0, a0);
	SetUV(UVs, 11, a1, a0);
	
	// Left
	SetVertex(Vertices, 12, -unit, +unit, +unit);
	SetVertex(Vertices, 13, -unit, +unit, -unit);
	SetVertex(Vertices, 14, -unit, -unit, +unit);
	SetVertex(Vertices, 15, -unit, -unit, -unit);
	SetUV(UVs, 12, a0, a1);
	SetUV(UVs, 13, a1, a1);
	SetUV(UVs, 14, a0, a0);
	SetUV(UVs, 15, a1, a0);
	
	// Top
	SetVertex(Vertices, 16, -unit, +unit, +unit);
	SetVertex(Vertices, 17, +unit, +unit, +unit);
	SetVertex(Vertices, 18, -unit, +unit, -unit);
	SetVertex(Vertices, 19, +unit, +unit, -unit);
	SetUV(UVs, 16, a0, a1);
	SetUV(UVs, 17, a1, a1);
	SetUV(UVs, 18, a0, a0);
	SetUV(UVs, 19, a1, a0);
	
	// Bottom
	SetVertex(Vertices, 20, -unit, -unit, -unit);
	SetVertex(Vertices, 21, +unit, -unit, -unit);
	SetVertex(Vertices, 22, -unit, -unit, +unit);
	SetVertex(Vertices, 23, +unit, -unit, +unit);
	SetUV(UVs, 20, a0, a1);
	SetUV(UVs, 21, a1, a1);
	SetUV(UVs, 22, a0, a0);
	SetUV(UVs, 23, a1, a0);
	
	for (int i=0; i<24*3; i++) (*Vertices)[i] = VERTTYPEMUL((*Vertices)[i], f2vt(scale));
}

/*!***************************************************************************
 @Function		PVRTDestroySkybox
 @Input			Vertices	Vertices array to destroy
 @Input			UVs			UVs array to destroy
 @Description	Destroy the memory allocated for a skybox
 *****************************************************************************/
void DestroySkybox(VERTTYPE* Vertices, VERTTYPE* UVs)
{
	delete [] Vertices;
	delete [] UVs;
}

