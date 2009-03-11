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

CDisplayText * AppDisplayText;
CTexture * Textures;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

int frames;
float frameRate;


/*****************************************************************************
 ** DEFINES
 *****************************************************************************/
const unsigned int m_ui32VBONo = 2;

#ifdef ENABLE_LOAD_TIME_STRIP
const unsigned int m_ui32IndexVBONo = 3;
const unsigned int m_ui32PageNo		= 3;
#else
const unsigned int m_ui32IndexVBONo = 2;
const unsigned int m_ui32PageNo		= 2;
#endif

#define VIEW_DISTANCE		f2vt(35)

// Times in milliseconds
#define TIME_AUTO_SWITCH	(4000000)
#define TIME_FPS_UPDATE		(10)

// Assuming a 320:480 aspect ratio:
#define CAM_ASPECT	f2vt(((float) 320 / (float) 480))
#define CAM_NEAR	f2vt(0.1f)
#define CAM_FAR		f2vt(1000.0f)

CPVRTModelPOD		*m_Model;	// Model
CPVRTModelPOD		*m_ModelOpt;	// Triangle optimized model
	
// not working hangs in TriStripList
//#define ENABLE_LOAD_TIME_STRIP

#ifdef ENABLE_LOAD_TIME_STRIP
unsigned short		*m_pNewIdx;		// Optimized model's indices

// There is some processing to be done once only; this flags marks whether it has been done.
int				m_nInit;
#endif

// OpenGL handles for textures and VBOs
GLuint*	m_puiVbo;
GLuint*	m_puiIndexVbo;
GLuint	m_Texture;

// View and Projection Matrices
MATRIX	m_mView, m_mProj;
VERTTYPE	m_fViewAngle;

// Used to switch mode (not optimized / optimized) after a while
unsigned long	m_uiSwitchTimeDiff;
int				m_nPage;

// Time variables
unsigned long	m_uiLastTime, m_uiTimeDiff;

// FPS variables
unsigned long	m_uiFPSTimeDiff, m_uiFPSFrameCnt;
float			m_fFPS;




/****************************************************************************
 ** Constants
 ****************************************************************************/

// Vectors for calculating the view matrix
VECTOR3 c_vOrigin = { 0, 0 ,0 };
VECTOR3	c_vUp = { 0, 1, 0 };

void CameraGetMatrix();
void ComputeViewMatrix();
void DrawModel( int iOptim );
void CalculateAndDisplayFrameRate();
void LoadVbos();

#ifdef ENABLE_LOAD_TIME_STRIP
void StripMesh();
#endif

bool CShell::InitApplication()
{
	AppDisplayText = new CDisplayText;  
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
		printf("Display text textures loaded\n");
	
	Textures = new CTexture;

	
	// Load POD File Data
	m_Model = (CPVRTModelPOD*)malloc(sizeof(CPVRTModelPOD));
	m_ModelOpt = (CPVRTModelPOD*)malloc(sizeof(CPVRTModelPOD));
	
	/*
	 Loads the scene from the .pod file into a CPVRTModelPOD object.
	 We could also export the scene as a header file and
	 load it with ReadFromMemory().
	 */
	char *buffer = new char[2048];
	GetResourcePathASCII(buffer, 2048);
	
	/* Gets the Data Path */
	char		*filename = new char[2048];
	sprintf(filename, "%s/Sphere_float.pod", buffer);
	if(m_Model->ReadFromFile(filename) != true)
		return false;
	
	sprintf(filename, "%s/SphereOpt_float.pod", buffer);
	if(m_ModelOpt->ReadFromFile(filename) != true)
		return false;

#ifdef ENABLE_LOAD_TIME_STRIP
	// Create a stripped version of the mesh at load time
	m_nInit = 2;
#endif
	
	// Init values to defaults
	m_nPage = 0;	
	
	
	/******************************
	 ** Create Textures           **
	 *******************************/
	sprintf(filename, "%s/model_texture.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_Texture))
	{
		return false;
	}
	
	/*********************************
	 ** View and Projection Matrices **
	 *********************************/
	
	/* Get Camera info from POD file */
	CameraGetMatrix();
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	// this is were the projection matrix calculated below in MatrixPerspectiveFovRH() in the CameraGetMatrix() call is applied
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
	
	/* Define front faces */
	glFrontFace(GL_CW);
	
	/* Sets the clear color */
	glClearColor(f2vt(0.6f), f2vt(0.8f), f2vt(1.0f), f2vt(1.0f));
	
	/* Reset the model view matrix to position the light */
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	/* Setup timing variables */
	struct timeval currTime = {0,0};
	gettimeofday(&currTime, NULL);
	m_uiLastTime = currTime.tv_usec;
	
	m_uiFPSFrameCnt = 0;
	m_fFPS = 0;
	m_fViewAngle = f2vt(0.0f);
	m_uiSwitchTimeDiff = 0;
	
#ifndef ENABLE_LOAD_TIME_STRIP
	LoadVbos();
#endif
	
	delete [] filename;
	delete [] buffer;


	return true;
}

/*!****************************************************************************
 @Function		LoadVbos
 @Description	Loads the mesh data required for this training course into
				vertex buffer objects
******************************************************************************/
void LoadVbos()
{
	if(!m_puiVbo)
		m_puiVbo = new GLuint[m_ui32VBONo];

	if(!m_puiIndexVbo)
		m_puiIndexVbo = new GLuint[m_ui32IndexVBONo];

	glGenBuffers(m_ui32VBONo, m_puiVbo);
	glGenBuffers(m_ui32IndexVBONo, m_puiIndexVbo);

	// Create vertex buffer for Model

	// Load vertex data into buffer object
	unsigned int uiSize = m_Model->pMesh[0].nNumVertex * m_Model->pMesh[0].sVertex.nStride;

	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[0]);
	glBufferData(GL_ARRAY_BUFFER, uiSize, m_Model->pMesh[0].pInterleaved, GL_STATIC_DRAW);

	// Load index data into buffer object if available
	uiSize = PVRTModelPODCountIndices(m_Model->pMesh[0]) * sizeof(GLshort);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[0]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, uiSize, m_Model->pMesh[0].sFaces.pData, GL_STATIC_DRAW);
	
	// Create vertex buffer for ModelOpt

	// Load vertex data into buffer object
	uiSize = m_ModelOpt->pMesh[0].nNumVertex * m_ModelOpt->pMesh[0].sVertex.nStride;

	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[1]);
	glBufferData(GL_ARRAY_BUFFER, uiSize, m_ModelOpt->pMesh[0].pInterleaved, GL_STATIC_DRAW);

	// Load index data into buffer object if available
	uiSize = PVRTModelPODCountIndices(m_ModelOpt->pMesh[0]) * sizeof(GLshort);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[1]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, uiSize, m_ModelOpt->pMesh[0].sFaces.pData, GL_STATIC_DRAW);

#ifdef ENABLE_LOAD_TIME_STRIP
	// Creat index data for the load time stripping
	uiSize = PVRTModelPODCountIndices(m_Model->pMesh[0]) * sizeof(GLshort);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[2]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, uiSize, m_pNewIdx, GL_STATIC_DRAW);
#endif

	// Unbind buffers
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

bool CShell::QuitApplication()
{

	m_Model->Destroy();
	m_ModelOpt->Destroy();
	
	delete[] m_puiVbo;
	delete[] m_puiIndexVbo;
	
#ifdef ENABLE_LOAD_TIME_STRIP
	free(m_pNewIdx);
#endif

	AppDisplayText->DeleteAllWindows();
	AppDisplayText->ReleaseTextures();

	
	delete AppDisplayText;
	
	/* Release all Textures */
	Textures->ReleaseTexture(m_Texture);
	
	delete Textures;
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
	unsigned long time;
	
	/* Clear the depth and frame buffer */
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
#ifdef ENABLE_LOAD_TIME_STRIP
	/*
	 Show a message on-screen then generate the necessary data on the
	 second frame.
	 */
	if(m_nInit)
	{
		--m_nInit;
		
		if(m_nInit)
		{
			AppDisplayText->DisplayDefaultTitle("Optimize Mesh", "", eDisplayTextLogoIMG);
			AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "Generating data...");
			AppDisplayText->Flush();	
			return true;
		}
		
		StripMesh();
		LoadVbos();
	}
#endif
	
	struct timeval currTime = {0,0};

	/*
	 Time
	 */
	//time = PVRShellGetTime();
	gettimeofday(&currTime, NULL);
	time = currTime.tv_usec;
	m_uiTimeDiff = ((time - m_uiLastTime) / 1000.0f);
	m_uiLastTime = time;
	
	// FPS
	m_uiFPSFrameCnt++;
	m_uiFPSTimeDiff += m_uiTimeDiff;
	if(m_uiFPSTimeDiff >= TIME_FPS_UPDATE)
	{
		m_fFPS = (m_uiFPSFrameCnt * 1000.0f)/ (float)m_uiFPSTimeDiff;
		m_uiFPSFrameCnt = 0;
		m_uiFPSTimeDiff = 0;
	}
	
	// Change mode when necessary
	m_uiSwitchTimeDiff += m_uiTimeDiff;
	if ((m_uiSwitchTimeDiff > TIME_AUTO_SWITCH)) // || PVRShellIsKeyPressed(PVRShellKeyNameACTION1))
	{
		m_uiSwitchTimeDiff = 0;
		++m_nPage;

		if(m_nPage >= (int) m_ui32PageNo)
			m_nPage = 0;
	}
	
	/* Calculate the model view matrix turning around the balloon */
	ComputeViewMatrix();
	
	/* Draw the model */
	DrawModel(m_nPage);
	
	/* Calculate the frame rate */
	CalculateAndDisplayFrameRate();

	return true;
}

/*******************************************************************************
 * Function Name  : ComputeViewMatrix
 * Description    : Calculate the view matrix turning around the balloon
 *******************************************************************************/
void ComputeViewMatrix()
{
	VECTOR3 vFrom;
	VERTTYPE factor;
	
	/* Calculate the angle of the camera around the balloon */
	vFrom.x = VERTTYPEMUL(VIEW_DISTANCE, cos(m_fViewAngle));
	vFrom.y = f2vt(0.0f);
	vFrom.z = VERTTYPEMUL(VIEW_DISTANCE, sin(m_fViewAngle));
	
	// Increase the rotation
	factor = f2vt(0.005f * (float)m_uiTimeDiff);
	m_fViewAngle += factor;
	
	// Ensure it doesn't grow huge and lose accuracy over time
	if(m_fViewAngle > PI)
		m_fViewAngle -= TWOPI;
	
	/* Compute and set the matrix */
	MatrixLookAtRH(m_mView, vFrom, c_vOrigin, c_vUp);
	glMatrixMode(GL_MODELVIEW);
	glLoadMatrixf(m_mView.f);
}

/*******************************************************************************
 * Function Name  : DrawModel
 * Inputs		  : iOptim
 * Description    : Draws the balloon
 *******************************************************************************/
void DrawModel( int iOptim )
{
	SPODMesh *pMesh;
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();

	MATRIX worldMatrix;
	m_Model->GetWorldMatrix(worldMatrix, m_Model->pNode[0]);
	glMultMatrixf(worldMatrix.f);

	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, m_Texture);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	// Enable States
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	// Set Data Pointers and bing the VBOs
	switch(iOptim)
	{
	default:
		pMesh = m_Model->pMesh;

		glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[0]);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[0]);
		break;
	case 1:
		pMesh = m_ModelOpt->pMesh;

		glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[1]);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[1]);
		break;
#ifdef ENABLE_LOAD_TIME_STRIP
	case 2:
		pMesh = m_Model->pMesh;

		glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[0]);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[2]);
		break;
#endif
	}

	// Used to display interleaved geometry
	glVertexPointer(3, VERTTYPEENUM, pMesh->sVertex.nStride, pMesh->sVertex.pData);
	glTexCoordPointer(2, VERTTYPEENUM, pMesh->psUVW[0].nStride, pMesh->psUVW[0].pData);

	// Draw
	glDrawElements(GL_TRIANGLES, pMesh->nNumFaces * 3, GL_UNSIGNED_SHORT, 0);

	// Disable States
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);

	// unbind the vertex buffers as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

	glPopMatrix();
}


/*******************************************************************************
 * Function Name  : CameraGetMatrix
 * Description    : Function to setup camera position
 *******************************************************************************/
void CameraGetMatrix()
{
	VECTOR3	vFrom, vTo, vUp;
	VERTTYPE		fFOV;
	
	vUp.x = f2vt(0.0f);	vUp.y = f2vt(1.0f);	vUp.z = f2vt(0.0f);
	
	if(m_Model->nNumCamera)
	{
		/* Get Camera data from POD Geometry File */
		fFOV = m_Model->GetCameraPos(vFrom, vTo, 0);
		fFOV = VERTTYPEMUL(fFOV, CAM_ASPECT);		// Convert from horizontal FOV to vertical FOV (0.75 assumes a 4:3 aspect ratio)
	}
	else
	{
		fFOV = f2vt(PIf / 6);
	}
	
	/* View */
	MatrixLookAtRH(m_mView, vFrom, vTo, vUp);
	
	/* Projection */
	MatrixPerspectiveFovRH(m_mProj, f2vt(fFOV), CAM_ASPECT, CAM_NEAR, CAM_FAR, true);
}

/*******************************************************************************
 * Function Name  : CalculateAndDisplayFrameRate
 * Description    : Computes and displays the on screen information
 *******************************************************************************/
void CalculateAndDisplayFrameRate()
{
//	char	pTitle[512];
	char	*pDesc;
	
	//sprintf(pTitle, "Optimize Mesh");
	
	/* Print text on screen */
	switch(m_nPage)
	{
		default:
			pDesc = "Indexed Triangle List: Unoptimized";
			break;
		case 1:
			pDesc = "Indexed Triangle List: Optimized (at export time)";
			break;
#ifdef ENABLE_LOAD_TIME_STRIP
		case 2:
			pDesc = "Indexed Triangle List: Optimized (at load time)";
			break;
#endif
	}

	
	AppDisplayText->DisplayDefaultTitle("Optimize Mesh", "", eDisplayTextLogoIMG);
	AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "fps: %3.2f", m_fFPS);
	AppDisplayText->DisplayText(0, 10, 0.4f, RGBA(255,255,255,255), "%s", pDesc);

	AppDisplayText->Flush();	
}

#ifdef ENABLE_LOAD_TIME_STRIP
/*******************************************************************************
 * Function Name  : StripMesh
 * Description    : Generates the stripped-at-load-time list.
 *******************************************************************************/
void StripMesh()
{
	// Make a copy of the indices as we want to keep the original
	m_pNewIdx = (unsigned short*)malloc(sizeof(unsigned short)*m_Model.pMesh->nNumFaces*3);
	memcpy(m_pNewIdx, m_Model.pMesh->sFaces.pData, sizeof(unsigned short)*m_Model.pMesh->nNumFaces*3);

	TriStripList(m_pNewIdx, m_Model.pMesh->nNumFaces);
}
#endif


