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
#include "UI.h"
#include "Macros.h"
#include "Geometry.h"
#include "MemoryManager.h"
#include "Macros.h"
#include "Pathes.h"

#include <stdio.h>
#include <sys/time.h>


/*************************
 Defines
 *************************/
#ifndef PI
#define PI 3.14159f
#endif

#define WIDTH 320
#define HEIGHT 480



CDisplayText * AppDisplayText;
CTexture * Textures;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

int frames;
float frameRate;

CPVRTModelPOD	*m_Scene;
GLuint			m_ui32TexID;


Vec4	m_LightPos;
long	m_i32Frame;
int		m_i32ClipPlaneNo;
bool	bClipPlaneSupported;

// Vertex Buffer Object (VBO) handles
GLuint*	m_puiVbo;
GLuint*	m_puiIndexVbo;

void DrawSphere();
void SetupUserClipPlanes();
void DisableClipPlanes();
void LoadVbos();

bool CShell::InitApplication()
{
	AppDisplayText = new CDisplayText;  
	Textures = new CTexture;
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
		printf("Display text textures loaded\n");

	m_puiVbo = 0;
	m_puiIndexVbo = 0;
	
	m_i32Frame = 0L;
	
	m_LightPos.x = f2vt(-1.0f);
	m_LightPos.y = f2vt(1.0f);
	m_LightPos.z = f2vt(1.0f);
	m_LightPos.w = f2vt(0.0f);
	
	MATRIX	mPerspective;

#ifdef GL_OES_VERSION_1_1
	bClipPlaneSupported = true;
#endif
	
	/* Retrieve max number of clip planes */
	if (bClipPlaneSupported)
	{
		glGetIntegerv(GL_MAX_CLIP_PLANES, &m_i32ClipPlaneNo);
	}
	if (m_i32ClipPlaneNo==0) bClipPlaneSupported = false;
	
	//SPVRTContext Context;
	
	m_Scene = (CPVRTModelPOD*)malloc(sizeof(CPVRTModelPOD));
	memset(m_Scene, 0, sizeof(CPVRTModelPOD));

	/*
		Loads the scene from the .pod file into a CPVRTModelPOD object.
		We could also export the scene as a header file and
		load it with ReadFromMemory().
	*/
	char *buffer = new char[2048];
	GetResourcePathASCII(buffer, 2048);

	/* Gets the Data Path */
	char		*filename = new char[2048];
	sprintf(filename, "%s/Mesh_float.pod", buffer);
	if(!m_Scene->ReadFromFile(filename))
	    return false;

	
	/* Load textures */
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Granite.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32TexID))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	/* Perspective matrix */
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	MatrixPerspectiveFovRH(mPerspective, f2vt(20.0f*(PI/180.0f)), f2vt((float)WIDTH/(float)HEIGHT), f2vt(10.0f), f2vt(1200.0f), true);
	glMultMatrixf(mPerspective.f);
	
	/* Modelview matrix */
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	/* Setup culling */
	glEnable(GL_CULL_FACE);
	glCullFace(GL_FRONT);
	
	// Setup single light
	glEnable(GL_LIGHTING);
	
	Vec4 fAmbient, fDiffuse, fSpecular;
	
	// Light 0 (White directional light)
	fAmbient  = Vec4(f2vt(0.4f), f2vt(0.4f), f2vt(0.4f), f2vt(1.0f));
	fDiffuse  = Vec4(f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f));
	fSpecular = Vec4(f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f));
	
	glLightfv(GL_LIGHT0, GL_AMBIENT,  fAmbient.ptr());
	glLightfv(GL_LIGHT0, GL_DIFFUSE,  fDiffuse.ptr());
	glLightfv(GL_LIGHT0, GL_SPECULAR, fSpecular.ptr());
	glLightfv(GL_LIGHT0, GL_POSITION, m_LightPos.ptr());
	
	glEnable(GL_LIGHT0);
	
	Vec4 ambient_light = Vec4(f2vt(0.8f), f2vt(0.8f), f2vt(0.8f), f2vt(1.0f));
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, ambient_light.ptr());
	
	// Setup all materials
	fAmbient  = Vec4(f2vt(0.1f), f2vt(0.1f), f2vt(0.1f), f2vt(1.0f));
	fDiffuse  = Vec4(f2vt(0.5f), f2vt(0.5f), f2vt(0.5f), f2vt(1.0f));
	fSpecular = Vec4(f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f));
	
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT,   fAmbient.ptr());
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE,   fDiffuse.ptr());
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR,  fSpecular.ptr());
	glMaterialf(GL_FRONT_AND_BACK,  GL_SHININESS, f2vt(10.0f));	// Nice and shiny so we don't get aliasing from the 1/2 angle
	
	// Set states
	glEnable(GL_DEPTH_TEST);
	
	// Set clear colour
	glClearColor(f2vt(0.0f), f2vt(0.0f), f2vt(0.0f), f2vt(1.0f));
	
	LoadVbos();
	delete [] filename;
	delete [] buffer;
	
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
	
	delete[] m_puiVbo;
	delete[] m_puiIndexVbo;
	
	Textures->ReleaseTexture(m_ui32TexID);
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
	// Set Vieweport size
	glViewport(0, 0, WIDTH, HEIGHT);
	
	// Clear the buffers
	glEnable(GL_DEPTH_TEST);
	
	glClearColor(f2vt(0.0f), f2vt(0.0f), f2vt(0.0f), f2vt(0.0f));
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// Lighting
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	
	// Texturing
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, m_ui32TexID);
	glActiveTexture(GL_TEXTURE0);

	glDisable(GL_BLEND);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	
	// Transformations
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	glTranslatef(f2vt(0.0f), f2vt(0.0f), f2vt(-500.0f));
	glRotatef(f2vt((float)m_i32Frame/5.0f),f2vt(0),f2vt(1),f2vt(0));
	
	// Draw sphere with user clip planes
	SetupUserClipPlanes();
	glDisable(GL_CULL_FACE);

	DrawSphere();

	glDisable(GL_TEXTURE_2D);
	DisableClipPlanes();
	
	/* Increase frame number */
	++m_i32Frame;
	
	/* Display info text */
	if (bClipPlaneSupported)
	{
		AppDisplayText->DisplayDefaultTitle("User Clip Planes", "User defined clip planes", eDisplayTextLogoIMG);
	}
	else
	{
		AppDisplayText->DisplayDefaultTitle("User Clip Planes", "User clip planes are not available", eDisplayTextLogoIMG);
	}
	
	AppDisplayText->Flush();	
	
	return true;
}

	/*!****************************************************************************
	 @Function		DrawSphere
	 @Description	Draw the rotating sphere
	 ******************************************************************************/
void DrawSphere()
{
	// Bind the VBO for the mesh
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[0]);

	// Bind the index buffer, won't hurt if the handle is 0
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[0]);

	// Enable States
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		
	// Set Data Pointers
	SPODMesh* pMesh = &m_Scene->pMesh[0];
		
	// Used to display non interleaved geometry
	glVertexPointer(3, VERTTYPEENUM, pMesh->sVertex.nStride, pMesh->sVertex.pData);
	glNormalPointer(VERTTYPEENUM, pMesh->sNormals.nStride, pMesh->sNormals.pData);
	glTexCoordPointer(2, VERTTYPEENUM, pMesh->psUVW->nStride, pMesh->psUVW[0].pData);
		
	// Indexed Triangle list
	glDrawElements(GL_TRIANGLES, pMesh->nNumFaces * 3, GL_UNSIGNED_SHORT, 0);
		
	/* Disable States */
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// Unbind the vertex buffers as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

	/*!****************************************************************************
	 @Function		SetupUserClipPlanes
	 @Description	Setup the user clip planes
	 ******************************************************************************/
	void SetupUserClipPlanes()
	{
	VERTTYPE ofs = f2vt(((float)sin(-m_i32Frame / 50.0f) * 10));

	if (m_i32ClipPlaneNo < 1) 
		return;
		
	VERTTYPE equation0[] = {f2vt(1), 0, f2vt(-1), f2vt(65)+ofs};
	glClipPlanef(GL_CLIP_PLANE0, equation0);
		glEnable( GL_CLIP_PLANE0 );
		
	if (m_i32ClipPlaneNo < 2) 
		return;

	VERTTYPE equation1[] = {f2vt(-1), 0, f2vt(-1), f2vt(65)+ofs};
	glClipPlanef( GL_CLIP_PLANE1, equation1);
	glEnable( GL_CLIP_PLANE1 );
		
	if (m_i32ClipPlaneNo < 3) 
		return;

	VERTTYPE equation2[] = {f2vt(-1), 0, f2vt(1), f2vt(65)+ofs};
	glClipPlanef( GL_CLIP_PLANE2, equation2);
	glEnable( GL_CLIP_PLANE2 );
		
	if (m_i32ClipPlaneNo < 4) 
		return;

	VERTTYPE equation3[] = {f2vt(1), 0, f2vt(1), f2vt(65)+ofs};
	glClipPlanef( GL_CLIP_PLANE3, equation3);
	glEnable( GL_CLIP_PLANE3 );
		
	if (m_i32ClipPlaneNo < 5) 
		return;

	VERTTYPE equation4[] = {0, f2vt(1), 0, f2vt(40)+ofs};
	glClipPlanef(GL_CLIP_PLANE4, equation4);
	glEnable( GL_CLIP_PLANE4 );
		
	if (m_i32ClipPlaneNo < 6) 
		return;

	VERTTYPE equation5[] = {0, f2vt(-1), 0, f2vt(40)+ofs};
	glClipPlanef(GL_CLIP_PLANE5, equation5);
	glEnable( GL_CLIP_PLANE5 );
}
	
	/*!****************************************************************************
	 @Function		DisableClipPlanes
	 @Description	Disable all the user clip planes
	 ******************************************************************************/
	void DisableClipPlanes()
	{
		if (!bClipPlaneSupported) return;
		glDisable( GL_CLIP_PLANE0 );
		glDisable( GL_CLIP_PLANE1 );
		glDisable( GL_CLIP_PLANE2 );
		glDisable( GL_CLIP_PLANE3 );
		glDisable( GL_CLIP_PLANE4 );
		glDisable( GL_CLIP_PLANE5 );
	}
	
