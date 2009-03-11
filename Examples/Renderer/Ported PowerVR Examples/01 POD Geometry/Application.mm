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


// Texture handle
GLuint			m_uiTex_base, m_uiTex_arm;

// Vertex Buffer Object (VBO) handles
GLuint*	m_puiVbo;
GLuint*	m_puiIndexVbo;

// 3D Model
CPVRTModelPOD	*m_Scene;

// Projection and Model View matrices
MATRIX		m_mProjection, m_mView;

// Array to lookup the textures for each material in the scene
GLuint*			m_puiTextures;

// Variables to handle the animation in a time-based manner
int				m_iTimePrev;
VERTTYPE		m_fFrame;

#define DEMO_FRAME_RATE	(1.0f / 30.0f)

// allocate in heap
CDisplayText * AppDisplayText;
CTexture * Textures;
int bookmark;

void LoadVbos();

bool CShell::InitApplication()
{
	AppDisplayText = (CDisplayText*)malloc(sizeof(CDisplayText));    
	memset(AppDisplayText, 0, sizeof(CDisplayText));
	Textures = (CTexture*)malloc(sizeof(CTexture));
	memset(Textures, 0, sizeof(CTexture));
	
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
	sprintf(filename, "%s/IntroducingPOD_float.pod", buffer);
	m_Scene->ReadFromFile(filename);
	

/*
#ifdef OGLESLITE
	m_Scene->ReadFromMemory(c_SCENE_FIXED_H);
#else
	m_Scene->ReadFromMemory(c_SCENE_FLOAT_H);
#endif
*/
	// The cameras are stored in the file. We check it contains at least one.
	if (m_Scene->nNumCamera == 0)
	{
//		LOG("The scene does not contain a camera", Logger::LOG_DATA);
		return false;
	}

	// Initialize variables used for the animation
	m_fFrame = 0;
	
	timeval tv;
	gettimeofday(&tv,NULL);
	m_iTimePrev = ((tv.tv_sec*1000) + (tv.tv_usec/1000.0));
	//m_iTimePrev = GetTimeInMs();
	
	// Sets the clear color
	glClearColor(f2vt(0.6f), f2vt(0.8f), f2vt(1.0f), f2vt(1.0f));

	// Enables texturing
	glEnable(GL_TEXTURE_2D);

	/*
		Loads the texture.
		For a more detailed explanation, see Texturing and IntroducingPVRTools
	*/
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/tex_base.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_uiTex_base))
	{
		return false;
	}
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/tex_arm.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_uiTex_arm))
	{
		return false;
	}
/*	
	if(!Textures->LoadTextureFromPointer((void*)tex_base, &m_uiTex_base))
	{
//		LOG("Cannot load the texture", Logger::LOG_DATA);
		return false;
	}
*/
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
/*
	if(!Textures->LoadTextureFromPointer((void*)tex_arm, &m_uiTex_arm))
	{
//		LOG("Cannot load the texture", Logger::LOG_DATA);
		return false;
	}
*/
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	// Enables lighting. See BasicTnL for a detailed explanation
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);

	/*
		Loads the light direction from the scene.
	*/
	// We check the scene contains at least one
	if (m_Scene->nNumLight == 0)
	{
//		LOG("ERROR: The scene does not contain a light", Logger::LOG_DATA);
		return false;
	}

	//	Initialize VBO data
	LoadVbos();

	/*
		Initializes an array to lookup the textures
		for each materials in the scene.
	*/
	m_puiTextures = new GLuint[m_Scene->nNumMaterial];

	for (int i=0; i<(int)m_Scene->nNumMaterial; i++)
	{
		m_puiTextures[i] = 0;
		SPODMaterial* pMaterial = &m_Scene->pMaterial[i];
		if (!strcmp(pMaterial->pszName, "Mat_Base"))
		{
			m_puiTextures[i] = m_uiTex_base;
		}
		else if (!strcmp(pMaterial->pszName, "Mat_Arm"))
		{
			m_puiTextures[i] = m_uiTex_arm;
		}
	}
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
		printf("Display text textures loaded");
		
	delete [] filename;
	delete [] buffer;

	return true;
}

bool CShell::QuitApplication()
{
	// Frees the texture lookup array
	delete [] m_puiTextures;

	// Frees the texture
	Textures->ReleaseTexture(m_uiTex_arm);
	Textures->ReleaseTexture(m_uiTex_base);

	// Frees the memory allocated for the scene
	m_Scene->Destroy();
	
	AppDisplayText->ReleaseTextures();
	
	free(AppDisplayText);
	free(Textures);
	free(m_Scene);
	
	delete[] m_puiVbo;
	delete[] m_puiIndexVbo;
	
//    HeapFactory::PrintInfo ();

//    HeapFactory::ReportMemoryLeaks (bookmark);

	return true;
}

bool CShell::UpdateScene()
{
    glEnable(GL_DEPTH_TEST);
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	
    glDisable(GL_CULL_FACE);
	
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


void DrawMesh(unsigned int ui32MeshID)
{
	SPODMesh& Mesh = m_Scene->pMesh[ui32MeshID];

	// bind the VBO for the mesh
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[ui32MeshID]);
	// bind the index buffer, won't hurt if the handle is 0
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[ui32MeshID]);

	// Setup pointers
	glVertexPointer(3, VERTTYPEENUM, Mesh.sVertex.nStride, Mesh.sVertex.pData);
	glTexCoordPointer(2, VERTTYPEENUM, Mesh.psUVW[0].nStride, Mesh.psUVW[0].pData);
	glNormalPointer(VERTTYPEENUM, Mesh.sNormals.nStride, Mesh.sNormals.pData);

	/*
		The geometry can be exported in 4 ways:
		- Indexed Triangle list
		- Non-Indexed Triangle list
		- Indexed Triangle strips
		- Non-Indexed Triangle strips
	*/
	if(Mesh.nNumStrips == 0)
	{
		if(m_puiIndexVbo[ui32MeshID])
		{
			// Indexed Triangle list
			glDrawElements(GL_TRIANGLES, Mesh.nNumFaces * 3, GL_UNSIGNED_SHORT, 0);
		}
		else
		{
			// Non-Indexed Triangle list
			glDrawArrays(GL_TRIANGLES, 0, Mesh.nNumFaces * 3);
		}
	}
	else
	{
		for(int i = 0; i < (int) Mesh.nNumStrips; ++i)
		{
			int offset = 0;
			if(m_puiIndexVbo[ui32MeshID])
			{
				// Indexed Triangle strips
				glDrawElements(GL_TRIANGLE_STRIP, Mesh.pnStripLength[i]+2, GL_UNSIGNED_SHORT, &((GLshort*)0)[offset]);
			}
			else
			{
				// Non-Indexed Triangle strips
				glDrawArrays(GL_TRIANGLE_STRIP, offset, Mesh.pnStripLength[i]+2);
			}
			offset += Mesh.pnStripLength[i]+2;
		}
	}

	// unbind the vertex buffers as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}


bool CShell::RenderScene()
{
	/*
		Calculates the frame number to animate in a time-based manner.
	*/
	timeval tv;
	gettimeofday(&tv,NULL);
	int iTime = ((tv.tv_sec*1000) + (tv.tv_usec/1000.0));
	//int iTime = GetTimeInMs();
	

	if(m_iTimePrev > iTime)
		m_iTimePrev = iTime;

	int iDeltaTime = iTime - m_iTimePrev;

	m_iTimePrev	= iTime;
	m_fFrame	+= VERTTYPEMUL(f2vt(iDeltaTime), f2vt(DEMO_FRAME_RATE));

//	if (m_fFrame > f2vt(m_Scene->nNumFrame-1))
//		m_fFrame = 0;
		
	while(m_fFrame > f2vt(m_Scene->nNumFrame-1))
		m_fFrame -= f2vt(m_Scene->nNumFrame-1);
		
	AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "frame: %3.f", m_fFrame);

	// Sets the scene animation to this frame
	m_Scene->SetFrame(m_fFrame);

	{
		VECTOR3	vFrom, vTo, vUp;
		VERTTYPE	fFOV;
		vUp.x = f2vt(0.0f);
		vUp.y = f2vt(1.0f);
		vUp.z = f2vt(0.0f);

		// We can get the camera position, target and field of view (fov) with GetCameraPos()
		fFOV = m_Scene->GetCameraPos( vFrom, vTo, 0);

		/*
			We can build the model view matrix from the camera position, target and an up vector.
			For this we use MatrixLookAtRH().
		*/
		MatrixLookAtRH(m_mView, vFrom, vTo, vUp);

		// Calculates the projection matrix
		//bool bRotate = PVRShellGet(prefIsRotated) && PVRShellGet(prefFullScreen);
	//		MatrixPerspectiveFovRH(MyPerspMatrix, f2vt(mCameraFOV), f2vt(((float) tw / (float) th)), f2vt(0.1f), f2vt(1000.0f), WIDESCREEN);

		MatrixPerspectiveFovRH(m_mProjection, fFOV, f2vt(480/320), f2vt(4.0f), f2vt(500.0f), true);

		// Loads the projection matrix
		glMatrixMode(GL_PROJECTION);
		glLoadMatrixf(m_mProjection.f);
	}

	// Specify the view matrix to OpenGL ES so we can specify the light in world space
	glMatrixMode(GL_MODELVIEW);
	glLoadMatrixf(m_mView.f);

	{
		// Reads the light direction from the scene.
		VECTOR4 vLightDirection;
		VECTOR3 vPos;
		m_Scene->GetLight(vPos, *(VECTOR3*)&vLightDirection, 0);
		vLightDirection.x = -vLightDirection.x;
		vLightDirection.y = -vLightDirection.y;
		vLightDirection.z = -vLightDirection.z;

		/*
			Sets the w component to 0, so when passing it to glLight(), it is
			considered as a directional light (as opposed to a spot light).
		*/
		vLightDirection.w = 0;

		// Specify the light direction in world space
		glLightfv(GL_LIGHT0, GL_POSITION, (VERTTYPE*)&vLightDirection);
	}

	// Enables the vertices, normals and texture coordinates arrays
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	/*
		A scene is composed of nodes. There are 3 types of nodes:
		- MeshNodes :
			references a mesh in the pMesh[].
			These nodes are at the beginning of the pNode[] array.
			And there are nNumMeshNode number of them.
			This way the .pod format can instantiate several times the same mesh
			with different attributes.
		- lights
		- cameras
		To draw a scene, you must go through all the MeshNodes and draw the referenced meshes.
	*/
	for (int i=0; i<(int)m_Scene->nNumMeshNode; i++)
	{
		SPODNode* pNode = &m_Scene->pNode[i];

		// Gets pMesh referenced by the pNode
//		SPODMesh* pMesh = &m_Scene->pMesh[pNode->nIdx];

		// Gets the node model matrix
		MATRIX mWorld;
		m_Scene->GetWorldMatrix(mWorld, *pNode);

		// Multiply the view matrix by the model (mWorld) matrix to get the model-view matrix
		MATRIX mModelView;
		MatrixMultiply(mModelView, mWorld, m_mView);
		glLoadMatrixf(mModelView.f);

		// Loads the correct texture using our texture lookup table
		if (pNode->nIdxMaterial == -1)
		{
			// It has no pMaterial defined. Use blank texture (0)
			glBindTexture(GL_TEXTURE_2D, 0);
		}
		else
		{
			glBindTexture(GL_TEXTURE_2D, m_puiTextures[pNode->nIdxMaterial]);
		}

		/*
			Now that the model-view matrix is set and the materials ready,
			call another function to actually draw the mesh.
		*/
		DrawMesh(pNode->nIdx);
	}
	
		// show text on the display
	AppDisplayText->DisplayDefaultTitle("POD Scene", "", eDisplayTextLogoIMG);

	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	
	AppDisplayText->Flush();	
	
	return true;
}

