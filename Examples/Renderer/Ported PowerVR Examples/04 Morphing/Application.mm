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
#include "Geometry.h"
#include "UI.h"
#include "App.h"
#include "MemoryManager.h"
#include "Macros.h"
#include "Pathes.h"

#include <stdio.h>
#include <sys/time.h>

// PVR texture files
const char c_szIrisTexFile[]	= "Iris.pvr";	// Eyes
const char c_szMetalTexFile[]	= "Metal.pvr";	// Skull
const char c_szFire02TexFile[]	= "Fire02.pvr";	// Background
const char c_szFire03TexFile[]	= "Fire03.pvr";	// Background

// POD file
const char c_szSceneFile[] = "EvilSkull_float.pod";

enum EMeshes
{
	eSkull,
	eJaw = 4
};



CDisplayText * AppDisplayText;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;
CTexture * Textures;

// Geometry Software Processing Defines
const unsigned int g_ui32NoOfMorphTargets = 4;

// Animation Define
const float g_fExprTime = 75.0f;

const unsigned int g_ui32NoOfTextures = 4;

int frames;
float frameRate;

/****************************************************************************
 ** DEFINES                                                                **
 ****************************************************************************/
#ifndef PI
#define PI 3.14159f
#endif


#define WIDTH 320
#define HEIGHT 480


CPVRTModelPOD *m_Scene;

// OpenGL handles for textures and VBOs
GLuint*	m_puiVbo;
GLuint*	m_puiIndexVbo;

// Objects
GLuint		m_ui32Texture[g_ui32NoOfTextures];

// Software processing buffers
VERTTYPE	*m_pMorphedVertices;
float		*m_pAVGVertices;
float		*m_pDiffVertices[g_ui32NoOfMorphTargets];

// Animation Params
float m_fSkullWeights[5];
float m_fExprTable[4][7];
float m_fJawRotation[7];
float m_fBackRotation[7];
int m_i32BaseAnim;
int m_i32TargetAnim;

// Generic
int m_i32Frame;

// m_LightPos
Vec4	m_LightPos;

VECTOR3 m_CameraPos, m_CameraTo, m_CameraUp;
MATRIX	m_mView;



/****************************************************************************
 ** Function Definitions
 ****************************************************************************/
void RenderSkull();
void RenderJaw();
void CalculateMovement(int nType);
void DrawQuad(float x, float y, float z, float Size, GLuint ui32Texture);
void DrawDualTexQuad(float x, float y, float z, float Size, GLuint ui32Texture1, GLuint ui32Texture2);
void LoadVbos();
void CreateMorphData();

bool CShell::InitApplication()
{
	AppDisplayText = new CDisplayText;  
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
		printf("Display text textures loaded\n");
	
	Textures = new CTexture;

	m_puiVbo = 0;
	m_puiIndexVbo = 0;
	m_pMorphedVertices = 0;
	m_pAVGVertices = 0; 
	m_i32BaseAnim = 0;
	m_i32TargetAnim = 0;
	m_i32Frame = 0;

	for(unsigned int i = 0; i < g_ui32NoOfMorphTargets; ++i)
		m_pDiffVertices[i] = 0;

	// Setup base constants in contructor

	// Camera and Light details
	m_LightPos  = Vec4(f2vt(-1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(0.0f));

	m_CameraPos = Vec3(f2vt(0.0f), f2vt(0.0f), f2vt(300.0f));
	m_CameraTo  = Vec3(f2vt(0.0f), f2vt(-30.0f), f2vt(0.0f));
	m_CameraUp  = Vec3(f2vt(0.0f), f2vt(1.0f), f2vt(0.0f));

	// Animation Table
	m_fSkullWeights[0] = 0.0f;
	m_fSkullWeights[1] = 1.0f;
	m_fSkullWeights[2] = 0.0f;
	m_fSkullWeights[3] = 0.0f;
	m_fSkullWeights[4] = 0.0f;

	m_fExprTable[0][0] = 1.0f;	m_fExprTable[1][0] = 1.0f;	m_fExprTable[2][0] = 1.0f;	m_fExprTable[3][0] = 1.0f;
	m_fExprTable[0][1] = 0.0f;	m_fExprTable[1][1] = 0.0f;	m_fExprTable[2][1] = 0.0f;	m_fExprTable[3][1] = 1.0f;
	m_fExprTable[0][2] = 0.0f;	m_fExprTable[1][2] = 0.0f;	m_fExprTable[2][2] = 1.0f;	m_fExprTable[3][2] = 1.0f;
	m_fExprTable[0][3] = 0.3f;	m_fExprTable[1][3] = 0.0f;	m_fExprTable[2][3] = 0.3f;	m_fExprTable[3][3] = 0.0f;
	m_fExprTable[0][4] =-1.0f;	m_fExprTable[1][4] = 0.0f;	m_fExprTable[2][4] = 0.0f;	m_fExprTable[3][4] = 0.0f;
	m_fExprTable[0][5] = 0.0f;	m_fExprTable[1][5] = 0.0f;	m_fExprTable[2][5] =-0.7f;	m_fExprTable[3][5] = 0.0f;
	m_fExprTable[0][6] = 0.0f;	m_fExprTable[1][6] = 0.0f;	m_fExprTable[2][6 ]= 0.0f;	m_fExprTable[3][6] =-0.7f;

	m_fJawRotation[0] = 45.0f;
	m_fJawRotation[1] = 25.0f;
	m_fJawRotation[2] = 40.0f;
	m_fJawRotation[3] = 20.0f;
	m_fJawRotation[4] = 45.0f;
	m_fJawRotation[5] = 25.0f;
	m_fJawRotation[6] = 30.0f;

	m_fBackRotation[0] = 0.0f;
	m_fBackRotation[1] = 25.0f;
	m_fBackRotation[2] = 40.0f;
	m_fBackRotation[3] = 90.0f;
	m_fBackRotation[4] = 125.0f;
	m_fBackRotation[5] = 80.0f;
	m_fBackRotation[6] = 30.0f;
	
	
//	VERTTYPE fVal[4];
//	int j;
	MATRIX		MyPerspMatrix;
	
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
	sprintf(filename, "%s/EvilSkull_float.pod", buffer);
	if(m_Scene->ReadFromFile(filename) != true) 
		return false;
	
	/***********************
	 ** LOAD TEXTURES     **
	 ***********************/
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Iris.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32Texture[0]))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Metal.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32Texture[1]))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Fire02.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32Texture[2]))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Fire03.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32Texture[3]))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	/******************************
	 ** GENERIC RENDER STATES     **
	 *******************************/
	
	// The Type Of Depth Test To Do
	glDepthFunc(GL_LEQUAL);
	
	// Enables Depth Testing
	glEnable(GL_DEPTH_TEST);
	
	// Enables Smooth Color Shading
	glShadeModel(GL_SMOOTH);
	
	// Blending mode
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	/* Create perspective matrix */
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	/* Culling */
	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);
	
	MatrixPerspectiveFovRH(MyPerspMatrix, f2vt(70.0f*(3.14f/180.0f)), f2vt((float)WIDTH/(float)HEIGHT), f2vt(10.0f), f2vt(10000.0f), true);
	glMultMatrixf(MyPerspMatrix.f);
	
	/* Create viewing matrix */
	MatrixLookAtRH(m_mView, m_CameraPos, m_CameraTo, m_CameraUp);

	glMatrixMode(GL_MODELVIEW);	
	glMultMatrixf(m_mView.f);
	
	/* Enable texturing */
	glEnable(GL_TEXTURE_2D);
	
	/* Lights (only one side lighting) */
	glEnable(GL_LIGHTING);
	
	// Light 0 (White directional light)
	Vec4 fAmbient  = Vec4(f2vt(0.2f), f2vt(0.2f), f2vt(0.2f), f2vt(1.0f));
	Vec4 fDiffuse  = Vec4(f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f));
	Vec4 fSpecular = Vec4(f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f));
	
	glLightfv(GL_LIGHT0, GL_AMBIENT,  fAmbient.ptr());
	glLightfv(GL_LIGHT0, GL_DIFFUSE,  fDiffuse.ptr());
	glLightfv(GL_LIGHT0, GL_SPECULAR, fSpecular.ptr());
	glLightfv(GL_LIGHT0, GL_POSITION, m_LightPos.ptr());
	
	glEnable(GL_LIGHT0);
	
	glDisable(GL_LIGHTING);
	
	// Create the data used for the morphing
	CreateMorphData();
		
	// Sets the clear color
	glClearColor(f2vt(0.0f), f2vt(0.0f), f2vt(0.0f), f2vt(1.0f));
	
	// Create vertex buffer objects
	LoadVbos();
	
	delete [] filename;
	delete [] buffer;
	
	return true;
}

void CreateMorphData()
{
	unsigned int i,j;

	unsigned int ui32VertexNo = m_Scene->pMesh[eSkull].nNumVertex;

	delete[] m_pMorphedVertices;
	delete[] m_pAVGVertices;

	m_pMorphedVertices = new VERTTYPE[ui32VertexNo * 3];
	m_pAVGVertices     = new float[ui32VertexNo * 3];

	for(i = 0; i < g_ui32NoOfMorphTargets; ++i)
	{
		delete[] m_pDiffVertices[i];
		m_pDiffVertices[i] = new float[ui32VertexNo * 3];
		memset(m_pDiffVertices[i], 0, sizeof(*m_pDiffVertices) * ui32VertexNo * 3);
	}

	unsigned char* pData[g_ui32NoOfMorphTargets]; 
	
	for(j = 0; j < g_ui32NoOfMorphTargets; ++j)
		pData[j] = m_Scene->pMesh[eSkull + j].pInterleaved;

	VERTTYPE *pVertexData;

	// Calculate AVG Model for Morphing
	for(i = 0; i < ui32VertexNo * 3; i += 3)
	{
		m_pAVGVertices[i + 0] = 0.0f;
		m_pAVGVertices[i + 1] = 0.0f;
		m_pAVGVertices[i + 2] = 0.0f;

		for(j = 0; j < g_ui32NoOfMorphTargets; ++j)
		{
			pVertexData = (VERTTYPE*) pData[j];

			m_pAVGVertices[i + 0] += vt2f(pVertexData[0]) * 0.25f;
			m_pAVGVertices[i + 1] += vt2f(pVertexData[1]) * 0.25f;
			m_pAVGVertices[i + 2] += vt2f(pVertexData[2]) * 0.25f;

			pData[j] += m_Scene->pMesh[eSkull + j].sVertex.nStride;
		}
	}

	for(j = 0; j < g_ui32NoOfMorphTargets; ++j)
		pData[j] = m_Scene->pMesh[eSkull + j].pInterleaved;

	// Calculate Differences for Morphing
	for(i = 0; i < ui32VertexNo * 3; i += 3)
	{
		for(j = 0; j < g_ui32NoOfMorphTargets; ++j)
		{
			pVertexData = (VERTTYPE*) pData[j];

			m_pDiffVertices[j][i + 0] = m_pAVGVertices[i + 0] - vt2f(pVertexData[0]);
			m_pDiffVertices[j][i + 1] = m_pAVGVertices[i + 1] - vt2f(pVertexData[1]);
			m_pDiffVertices[j][i + 2] = m_pAVGVertices[i + 2] - vt2f(pVertexData[2]);

			pData[j] += m_Scene->pMesh[eSkull + j].sVertex.nStride;
		}
	}
}

void LoadVbos()
{
	if(!m_puiVbo)
		m_puiVbo = new GLuint[2];

	if(!m_puiIndexVbo)
		m_puiIndexVbo = new GLuint[2];

	glGenBuffers(2, m_puiVbo);
	glGenBuffers(2, m_puiIndexVbo);

	// Create vertex buffer for Skull

	// Load vertex data into buffer object
	unsigned int uiSize = m_Scene->pMesh[eSkull].nNumVertex * m_Scene->pMesh[eSkull].sVertex.nStride;

	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[0]);
	glBufferData(GL_ARRAY_BUFFER, uiSize, m_Scene->pMesh[eSkull].pInterleaved, GL_STATIC_DRAW);

	// Load index data into buffer object if available
	uiSize = PVRTModelPODCountIndices(m_Scene->pMesh[eSkull]) * sizeof(GLshort);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[0]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, uiSize, m_Scene->pMesh[eSkull].sFaces.pData, GL_STATIC_DRAW);
	
	// Create vertex buffer for Jaw

	// Load vertex data into buffer object
	uiSize = m_Scene->pMesh[eJaw].nNumVertex * m_Scene->pMesh[eJaw].sVertex.nStride;

	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[1]);
	glBufferData(GL_ARRAY_BUFFER, uiSize, m_Scene->pMesh[eJaw].pInterleaved, GL_STATIC_DRAW);

	// Load index data into buffer object if available
	uiSize = PVRTModelPODCountIndices(m_Scene->pMesh[eJaw]) * sizeof(GLshort);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[1]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, uiSize, m_Scene->pMesh[eJaw].sFaces.pData, GL_STATIC_DRAW);

	// Unbind buffers
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}


bool CShell::QuitApplication()
{
	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;
	
	delete[] m_puiVbo;
	delete[] m_puiIndexVbo;

	delete[] m_pMorphedVertices;
	delete[] m_pAVGVertices;

	for(unsigned int i = 0; i < g_ui32NoOfMorphTargets; ++i)
		delete[] m_pDiffVertices[i];
		
	// release all textures
	glDeleteTextures(g_ui32NoOfTextures, m_ui32Texture);

	delete Textures;
	
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
	
	AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "fps: %3.2f", frameRate);
	
	return true;
}


bool CShell::RenderScene()
{
	unsigned int i;
	float fCurrentfJawRotation, fCurrentfBackRotation;
	float fFactor, fInvFactor;

	// Update Skull Weights and Rotations using Animation Info
	if(m_i32Frame > g_fExprTime)
	{
		m_i32Frame = 0;
		m_i32BaseAnim = m_i32TargetAnim;

		++m_i32TargetAnim;

		if(m_i32TargetAnim > 6)
		{
			m_i32TargetAnim = 0;
		}
	}

	fFactor = float(m_i32Frame) / g_fExprTime;
	fInvFactor = 1.0f - fFactor;

	m_fSkullWeights[0] = (m_fExprTable[0][m_i32BaseAnim] * fInvFactor) + (m_fExprTable[0][m_i32TargetAnim] * fFactor);
	m_fSkullWeights[1] = (m_fExprTable[1][m_i32BaseAnim] * fInvFactor) + (m_fExprTable[1][m_i32TargetAnim] * fFactor);
	m_fSkullWeights[2] = (m_fExprTable[2][m_i32BaseAnim] * fInvFactor) + (m_fExprTable[2][m_i32TargetAnim] * fFactor);
	m_fSkullWeights[3] = (m_fExprTable[3][m_i32BaseAnim] * fInvFactor) + (m_fExprTable[3][m_i32TargetAnim] * fFactor);

	fCurrentfJawRotation = m_fJawRotation[m_i32BaseAnim] * fInvFactor + (m_fJawRotation[m_i32TargetAnim] * fFactor);
	fCurrentfBackRotation = m_fBackRotation[m_i32BaseAnim] * fInvFactor + (m_fBackRotation[m_i32TargetAnim] * fFactor);

	// Update Base Animation Value - FrameBased Animation for now
	++m_i32Frame;

	// Update Skull Vertex Data using Animation Params
	for(i = 0; i < m_Scene->pMesh[eSkull].nNumVertex * 3; ++i)
	{
		m_pMorphedVertices[i]= f2vt(m_pAVGVertices[i] + (m_pDiffVertices[0][i] * m_fSkullWeights[0]) \
													  + (m_pDiffVertices[1][i] * m_fSkullWeights[1]) \
													  + (m_pDiffVertices[2][i] * m_fSkullWeights[2]) \
													  + (m_pDiffVertices[3][i] * m_fSkullWeights[3]));

	}

	// Buffer Clear
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	// Render Skull and Jaw Opaque with Lighting
	glDisable(GL_BLEND);		// Opaque = No Blending
	glEnable(GL_LIGHTING);		// Lighting On

	// Set skull and jaw texture
	glBindTexture(GL_TEXTURE_2D, m_ui32Texture[1]);

	// Enable and set vertices, normals and index data
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	// Render Animated Jaw - Rotation Only
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();

	glLoadIdentity();

	glMultMatrixf(m_mView.f);

	glTranslatef(f2vt(0),f2vt(-50.0f),f2vt(-50.0f));

	glRotatef(f2vt(-fCurrentfJawRotation), f2vt(1.0f), f2vt(0.0f), f2vt(0.0f));
	glRotatef(f2vt(fCurrentfJawRotation) - f2vt(30.0f), f2vt(0), f2vt(1.0f), f2vt(-1.0f));

	RenderJaw();

	glPopMatrix();

	// Render Morphed Skull
	glPushMatrix();

	glRotatef(f2vt(fCurrentfJawRotation) - f2vt(30.0f), f2vt(0), f2vt(1.0f), f2vt(-1.0f));

	RenderSkull();

	// Render Eyes and Background with Alpha Blending and No Lighting

	glEnable(GL_BLEND);			// Enable Alpha Blending
	glDisable(GL_LIGHTING);		// Disable Lighting

	
	// Disable the normals as they aren't needed anymore
	glDisableClientState(GL_NORMAL_ARRAY);

	// Render Eyes using Skull Model Matrix
	DrawQuad(-30.0f ,0.0f ,50.0f ,20.0f , m_ui32Texture[0]);
	DrawQuad( 33.0f ,0.0f ,50.0f ,20.0f , m_ui32Texture[0]);

	glPopMatrix();

	// Render Dual Texture Background with different base color, rotation, and texture rotation
	glPushMatrix();

	glDisable(GL_BLEND);			// Disable Alpha Blending

	glColor4f(f2vt(0.7f+0.3f*((m_fSkullWeights[0]))), f2vt(0.7f), f2vt(0.7f), f2vt(1.0f));	// Animated Base Color
	glTranslatef(f2vt(10.0f), f2vt(-50.0f), f2vt(0.0f));
	glRotatef(f2vt(fCurrentfBackRotation*4.0f),f2vt(0),f2vt(0),f2vt(-1.0f));	// Rotation of Quad

	// Animated Texture Matrix
	glActiveTexture(GL_TEXTURE0);
	glMatrixMode(GL_TEXTURE);
	glLoadIdentity();

	glTranslatef(f2vt(-0.5f), f2vt(-0.5f), f2vt(0.0f));
	glRotatef(f2vt(fCurrentfBackRotation*-8.0f), f2vt(0), f2vt(0), f2vt(-1.0f));
	glTranslatef(f2vt(-0.5f), f2vt(-0.5f), f2vt(0.0f));

	// Draw Geometry
	DrawDualTexQuad (0.0f ,0.0f ,-50.0f, 480.0f, m_ui32Texture[3], m_ui32Texture[2]);

	// Disable Animated Texture Matrix
	glActiveTexture(GL_TEXTURE0);
	glMatrixMode(GL_TEXTURE);
	glLoadIdentity();

	// Make sure to disable the arrays
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);

	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();

	// Reset Colour
	glColor4f(f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f));

	
	// show text on the display
	AppDisplayText->DisplayDefaultTitle("Morphing", "", eDisplayTextLogoIMG);
	
	AppDisplayText->Flush();	
	
	return true;
}


/*******************************************************************************
 * Function Name  : RenderSkull
 * Input		  : Texture Pntr and Filter Mode
 * Returns        :
 * Global Used    :
 * Description    : Renders the Skull data using the Morphed Data Set.
 *******************************************************************************/
void RenderSkull ()
{
	SPODMesh& Mesh = m_Scene->pMesh[eSkull];

	glVertexPointer(3, VERTTYPEENUM,  sizeof(VERTTYPE) * 3, m_pMorphedVertices);

	// Bind the jaw vertex buffers
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[0]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[0]);

	// Setup pointers
	glNormalPointer(VERTTYPEENUM, Mesh.sNormals.nStride, Mesh.sNormals.pData);
	glTexCoordPointer(2, VERTTYPEENUM, Mesh.psUVW[0].nStride, Mesh.psUVW[0].pData);

	glDrawElements(GL_TRIANGLES, Mesh.nNumFaces * 3, GL_UNSIGNED_SHORT, 0);

	// unbind the vertex buffers as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	
}

/*******************************************************************************
 * Function Name  : RenderJaw
 * Input		  : Texture Pntr and Filter Mode
 * Returns        :
 * Global Used    :
 * Description    : Renders the Skull Jaw - uses direct data no morphing
 *******************************************************************************/
void RenderJaw ()
{
	SPODMesh& Mesh = m_Scene->pMesh[eJaw];

	// Bind the jaw vertex buffers
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[1]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[1]);

	// Setup pointers
	glVertexPointer(3, VERTTYPEENUM, Mesh.sVertex.nStride, Mesh.sVertex.pData);
	glNormalPointer(VERTTYPEENUM, Mesh.sNormals.nStride, Mesh.sNormals.pData);
	glTexCoordPointer(2, VERTTYPEENUM, Mesh.psUVW[0].nStride, Mesh.psUVW[0].pData);

	glDrawElements(GL_TRIANGLES, Mesh.nNumFaces * 3, GL_UNSIGNED_SHORT, 0);
	
	// unbind the vertex buffers as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

/*******************************************************************************
 * Function Name  : DrawQuad
 * Input		  : Size, (x,y,z) and texture pntr
 * Returns        :
 * Global Used    :
 * Description    : Basic Draw Quad with Size in Location X, Y, Z.
 *******************************************************************************/
void DrawQuad (float x,float y,float z,float Size, GLuint ui32Texture)
{
	// Bind correct texture
	glBindTexture(GL_TEXTURE_2D, ui32Texture);
	
	/* Vertex Data */
	VERTTYPE verts[] =		{	f2vt(x+Size), f2vt(y-Size), f2vt(z),
		f2vt(x+Size), f2vt(y+Size), f2vt(z),
		f2vt(x-Size), f2vt(y-Size), f2vt(z),
		f2vt(x-Size), f2vt(y+Size), f2vt(z)
	};
	
	VERTTYPE texcoords[] =	{	f2vt(0.0f), f2vt(1.0f),
		f2vt(0.0f), f2vt(0.0f),
		f2vt(1.0f), f2vt(1.0f),
		f2vt(1.0f), f2vt(0.0f)
	};
	
	// Set Arrays - Only need Vertex Array and Tex Coord Array
	glVertexPointer(3,VERTTYPEENUM,0,verts);
	glTexCoordPointer(2,VERTTYPEENUM,0,texcoords);
	
	// Draw Strip
	glDrawArrays(GL_TRIANGLE_STRIP,0,4);
}

/*******************************************************************************
 * Function Name  : DrawDualTexQuad
 * Input		  : Size, (x,y,z) and texture pntr
 * Returns        :
 * Global Used    :
 * Description    : Basic Draw Dual Textured Quad with Size in Location X, Y, Z.
 *******************************************************************************/
void DrawDualTexQuad (float x,float y,float z,float Size, GLuint pTexture1, GLuint pTexture2)
{
	/* Set Texture and Texture Options */
	glBindTexture(GL_TEXTURE_2D, pTexture1);
	
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, pTexture2);
	glEnable(GL_TEXTURE_2D);
	
	/* Vertex Data */
	VERTTYPE verts[] =		{	f2vt(x+Size), f2vt(y-Size), f2vt(z),
		f2vt(x+Size), f2vt(y+Size), f2vt(z),
		f2vt(x-Size), f2vt(y-Size), f2vt(z),
		f2vt(x-Size), f2vt(y+Size), f2vt(z)
	};
	
	VERTTYPE texcoords[] =	{	f2vt(0.0f), f2vt(1.0f),
		f2vt(0.0f), f2vt(0.0f),
		f2vt(1.0f), f2vt(1.0f),
		f2vt(1.0f), f2vt(0.0f)
	};
	
	// Set Arrays - Only need Vertex Array and Tex Coord Arrays
	glVertexPointer(3,VERTTYPEENUM,0,verts);
	
    glClientActiveTexture(GL_TEXTURE0);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glTexCoordPointer(2,VERTTYPEENUM,0,texcoords);
	
	glClientActiveTexture(GL_TEXTURE1);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glTexCoordPointer(2,VERTTYPEENUM,0,texcoords);
	
	/* Draw Strip */
	glDrawArrays(GL_TRIANGLE_STRIP,0,4);
	
	/* Disable Arrays */
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glClientActiveTexture(GL_TEXTURE0);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, 0);
	glDisable(GL_TEXTURE_2D);
	
	glActiveTexture(GL_TEXTURE0);
	
}

