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

#define WIDTH 320
#define HEIGHT 480


CDisplayText * AppDisplayText;
CTexture * Textures;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

int frames;
float frameRate;

enum EMesh
{
	eGlass,
	eVase
};

// 3D Model
CPVRTModelPOD	*m_Scene;

// OpenGL handles for textures and VBOs
GLuint	m_uiBackTex;
GLuint	m_uiFloraTex;
GLuint	m_uiReflectTex;

GLuint*	m_puiVbo;
GLuint*	m_puiIndexVbo;

// Array to lookup the textures for each material in the scene
GLuint*	m_pui32Textures;

// Rotation variables
VERTTYPE m_fAngleX, m_fAngleY;

MATRIX m_mProjection;
MATRIX m_mView;

// Class for drawing the background
GLuint	m_uiBackground32Vbo;
GLsizei m_i32BackgroundStride;
unsigned char* m_pBackgroundVertexOffset;
unsigned char* m_pBackgroundTextureOffset;

bool m_bInit;

VERTTYPE *m_pUVs;

/****************************************************************************
 ** Function Definitions
 ****************************************************************************/
void LoadVbos();
void DrawMesh(unsigned int ui32MeshID);
void DrawReflectiveMesh(unsigned int ui32MeshID, MATRIX *pNormalTx);

void BackGroundDestroy();
bool BackgroundDraw(const GLuint ui32Texture);
bool BackgroundInit(bool bRotate);


bool CShell::InitApplication()
{
	AppDisplayText = new CDisplayText;  
	Textures = new CTexture;
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
				printf("Display text textures loaded\n");

	m_puiVbo = 0;
	m_puiIndexVbo = 0;
	m_fAngleX = 0;
	m_fAngleY = 0;

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
	sprintf(filename, "%s/Vase_float.pod", buffer);
	if(!m_Scene->ReadFromFile(filename))
	    return false;

	
	MATRIX MyPerspMatrix;
	
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Backgrnd.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_uiBackTex))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Flora.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_uiFloraTex))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Reflection.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_uiReflectTex))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	
	//	Initialize VBO data
	LoadVbos();
	
	m_bInit = false;
	
	// Initialize Background
	if(BackgroundInit(1) != true)
		return false;


	/*
		Build an array to map the textures within the pod file
		to the textures we loaded earlier.
	*/

	m_pui32Textures = new GLuint[m_Scene->nNumMaterial];

	for(unsigned int i = 0; i < m_Scene->nNumMaterial; ++i)
	{
		m_pui32Textures[i] = 0;
		SPODMaterial* pMaterial = &m_Scene->pMaterial[i];

		if(!strcmp(pMaterial->pszName, "Flora"))
			m_pui32Textures[i] = m_uiFloraTex;
		else if(!strcmp(pMaterial->pszName, "Reflection"))
			m_pui32Textures[i] = m_uiReflectTex;
	}
	
	// pre-allocate memory for the vase for UVs of meshes
	// this is used in the ReflectiveMesh drawcall
	// moved it up here because it slowed down the app substantially
	unsigned int ui32MeshID = m_Scene->pNode[eVase].nIdx;
	
	// 
	SPODMesh& Mesh = m_Scene->pMesh[ui32MeshID];
	
	// 	
	m_pUVs = new VERTTYPE[2 * Mesh.nNumVertex];
	
	/* Calculate projection matrix */
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	MatrixPerspectiveFovRH(MyPerspMatrix, f2vt(35.0f*(3.14f/180.0f)), f2vt((float)WIDTH/(float)HEIGHT), f2vt(10.0f), f2vt(1200.0f), true);
	glMultMatrixf(MyPerspMatrix.f);
	
	/* Enable texturing */
	glEnable(GL_TEXTURE_2D);
	
	// Setup clear colour
	glClearColor(f2vt(1.0f),f2vt(1.0f),f2vt(1.0f),f2vt(1.0f));

	// Set blend mode
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
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

	
	/* Release textures */
	Textures->ReleaseTexture(m_uiBackTex);
	Textures->ReleaseTexture(m_uiFloraTex);
	Textures->ReleaseTexture(m_uiReflectTex);
	
	delete[] m_pui32Textures;
	m_pui32Textures = 0;
	
	delete[] m_puiVbo;
	delete[] m_puiIndexVbo;
	delete[] m_pUVs;
	
	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;
	delete Textures;
	
	// Frees the memory allocated for the scene
	m_Scene->Destroy();
	free(m_Scene);

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
	MATRIX RotationMatrix, TmpX, TmpY;
	
	/* Set up viewport */
	glViewport(0, 0, WIDTH, HEIGHT);
	
	/* Increase rotation angles */
	m_fAngleX += VERTTYPEDIV(PI, f2vt(100.0f));
	m_fAngleY += VERTTYPEDIV(PI, f2vt(150.0f));
	
	if(m_fAngleX >= PI)
		m_fAngleX -= TWOPI;
	
	if(m_fAngleY >= PI)
		m_fAngleY -= TWOPI;
	
	// Clear the buffers
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// Setup the vase rotation
	
	/* Calculate rotation matrix */
	MatrixRotationX(TmpX, m_fAngleX);
	MatrixRotationY(TmpY, m_fAngleY);
	MatrixMultiply(RotationMatrix, TmpX, TmpY);
	
	// Modelview matrix
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glTranslatef(f2vt(0.0f), f2vt(0.0f), f2vt(-200.0f));
	glMultMatrixf(RotationMatrix.f);
	
	// Draw the scene
	
	// draw a background image
	BackgroundDraw(m_uiBackTex);
	
	// Enable client states
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// Enable depth test
	glEnable(GL_DEPTH_TEST);
	
	// Draw vase outer
	glBindTexture(GL_TEXTURE_2D, m_pui32Textures[m_Scene->pNode[eVase].nIdxMaterial]);
	DrawReflectiveMesh(m_Scene->pNode[eVase].nIdx, &RotationMatrix);
	
	// Draw glass
	glEnable(GL_BLEND);
	
	glBindTexture(GL_TEXTURE_2D, m_pui32Textures[m_Scene->pNode[eGlass].nIdxMaterial]);
	
	// Pass 1: only render back faces (model has reverse winding)
	glFrontFace(GL_CW);
	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);
	
	DrawMesh(m_Scene->pNode[eGlass].nIdx);
	
	// Pass 2: only render front faces (model has reverse winding)
	glCullFace(GL_FRONT);
	DrawMesh(m_Scene->pNode[eGlass].nIdx);
	
	// Disable blending as it isn't needed
	glDisable(GL_BLEND);
	
	// Disable client states
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// show text on the display
	AppDisplayText->DisplayDefaultTitle("Vase", "Translucency and reflections", eDisplayTextLogoIMG);
	
	AppDisplayText->Flush();	
	
	return true;
}

/*!****************************************************************************
 @Function		DrawReflectiveMesh
 @Input			ui32MeshID ID of mesh to draw
 @Input			pNormalTx Rotation matrix
 @Description	Draws a mesh with the reflection
******************************************************************************/
void DrawReflectiveMesh(unsigned int ui32MeshID, MATRIX *pNormalTx)
{
	SPODMesh& Mesh = m_Scene->pMesh[ui32MeshID];
	
	// this is so wrong ...	
//	VERTTYPE		*pUVs = new VERTTYPE[2 * Mesh.nNumVertex];
	MATRIX		EnvMapMatrix;
	unsigned int	i;
	
	// Calculate matrix for environment mapping: simple multiply by 0.5
	for(i = 0; i < 16; ++i)
		EnvMapMatrix.f[i] = VERTTYPEMUL(pNormalTx->f[i], f2vt(0.5f));

	unsigned char* pNormals = Mesh.pInterleaved + (size_t) Mesh.sNormals.pData;
	
	/* Calculate UVs for environment mapping */
	for(i = 0; i < Mesh.nNumVertex; ++i)
	{
		VERTTYPE *pVTNormals = (VERTTYPE*) pNormals;

		m_pUVs[2*i] =	VERTTYPEMUL(pVTNormals[0], EnvMapMatrix.f[0]) +
								VERTTYPEMUL(pVTNormals[1], EnvMapMatrix.f[4]) +
								VERTTYPEMUL(pVTNormals[2], EnvMapMatrix.f[8]) +
		f2vt(0.5f);
		
		m_pUVs[2*i+1] =	VERTTYPEMUL(pVTNormals[0], EnvMapMatrix.f[1]) +
								VERTTYPEMUL(pVTNormals[1], EnvMapMatrix.f[5]) +
								VERTTYPEMUL(pVTNormals[2], EnvMapMatrix.f[9]) +
		f2vt(0.5f);

		pNormals += Mesh.sNormals.nStride;
	}
	
	// Bind the vertex buffers
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[ui32MeshID]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[ui32MeshID]);
	
	// Setup pointers
	glVertexPointer(3, VERTTYPEENUM, Mesh.sVertex.nStride, Mesh.sVertex.pData);
	
	// unbind the vertex buffer as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	glTexCoordPointer(2, VERTTYPEENUM, 0, m_pUVs);
	
	glDrawElements(GL_TRIANGLES, Mesh.nNumFaces * 3, GL_UNSIGNED_SHORT, 0);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

//	delete[] pUVs;
}

/*!****************************************************************************
 @Function		DrawMesh
 @Input			ID of mesh to draw
 @Description	Draws a mesh.
******************************************************************************/
void DrawMesh(unsigned int ui32MeshID)
{
	SPODMesh& Mesh = m_Scene->pMesh[ui32MeshID];
	
	// Bind the vertex buffers
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[ui32MeshID]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[ui32MeshID]);
	
	// Setup pointers
	glVertexPointer(3, VERTTYPEENUM, Mesh.sVertex.nStride, Mesh.sVertex.pData);
	glTexCoordPointer(2, VERTTYPEENUM, Mesh.psUVW[0].nStride, Mesh.psUVW[0].pData);
	
	glDrawElements(GL_TRIANGLES, Mesh.nNumFaces * 3, GL_UNSIGNED_SHORT, 0);

	// unbind the vertex buffers as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}




void BackgroundDestroy()
{
	m_bInit = false;
}


bool BackgroundInit(bool bRotate)
{
	BackgroundDestroy();

	// The vertex data for non-rotated
	VERTTYPE afVertexData[20] = {f2vt(-1.0f), f2vt(-1.0f), f2vt(1.0f),  // Position
		f2vt( 0.0f), f2vt( 0.0f),				// Texture coordinates
		f2vt( 1.0f), f2vt(-1.0f), f2vt(1.0f),
		f2vt( 1.0f), f2vt( 0.0f),
		f2vt(-1.0f), f2vt( 1.0f), f2vt(1.0f),
		f2vt( 0.0f), f2vt( 1.0f),
		f2vt( 1.0f), f2vt( 1.0f), f2vt(1.0f),
	f2vt( 1.0f), f2vt( 1.0f)};
	
	// The vertex data for rotated
	VERTTYPE afVertexDataRotated[20] = {f2vt(-1.0f), f2vt( 1.0f), f2vt(1.0f),
		f2vt( 1.0f), f2vt( 1.0f),
		f2vt(-1.0f), f2vt(-1.0f), f2vt(1.0f),
		f2vt( 0.0f), f2vt( 1.0f),
		f2vt( 1.0f), f2vt( 1.0f), f2vt(1.0f),
		f2vt( 1.0f), f2vt( 0.0f),
		f2vt( 1.0f), f2vt(-1.0f), f2vt(1.0f),
	f2vt( 0.0f), f2vt( 0.0f)};
	
	
	glGenBuffers(1, &m_uiBackground32Vbo);
	
	unsigned int uiSize = 4 * (sizeof(VERTTYPE) * 5); // 4 vertices * stride (5 verttypes per vertex (3 pos + 2 uv))
	
	// Bind the VBO
	glBindBuffer(GL_ARRAY_BUFFER, m_uiBackground32Vbo);
	
	// Set the buffer's data
	glBufferData(GL_ARRAY_BUFFER, uiSize, bRotate ? afVertexDataRotated : afVertexData, GL_STATIC_DRAW);
	
	// Setup the vertex and texture data pointers for conveniece
	m_pBackgroundVertexOffset  = 0;
	m_pBackgroundTextureOffset = (unsigned char*) (sizeof(VERTTYPE) * 3);
	
	// Setup the stride variable
	m_i32BackgroundStride = sizeof(VERTTYPE) * 5;
	
	// All initialised
	m_bInit = true;
	
	// Unbind the VBO
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	return true;
}


/*!***************************************************************************
 @Function		Draw
 @Input			ui32Texture	Texture to use
 @Return 		PVR_SUCCESS on success
 @Description	Draws a texture on a quad covering the whole screen.
 *****************************************************************************/
bool BackgroundDraw(const GLuint ui32Texture)
{
	if(!m_bInit)
		return false;
	
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, ui32Texture);
	
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_LIGHTING);
	
	// Store matrices and set them to Identity
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	
	glDisableClientState(GL_COLOR_ARRAY);
	
	// Set state
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// Bind the VBO
	glBindBuffer(GL_ARRAY_BUFFER, m_uiBackground32Vbo);
	
	// set pointers
	glVertexPointer(3  ,VERTTYPEENUM,m_i32BackgroundStride, m_pBackgroundTextureOffset);
	glTexCoordPointer(2,VERTTYPEENUM,m_i32BackgroundStride, m_pBackgroundTextureOffset);
	
	// Render geometry
	glDrawArrays(GL_TRIANGLE_STRIP,0,4);
	
	// Disable client states
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// Unbind the VBO
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	// Recover matrices
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	
	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
	
	return true;
}

