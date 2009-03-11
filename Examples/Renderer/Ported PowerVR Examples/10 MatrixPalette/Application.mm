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
#include "Timer.h"
#include "Pathes.h"

#include <stdio.h>
#include <sys/time.h>

#define CAM_ASPECT	(1.333333333f)
#define CAM_NEAR	(3000.0f)
#define CAM_FAR		(4000.0f)


// Texture handle
GLuint			m_ui32MalletTexture;

// 3D Model
CPVRTModelPOD	* m_Scene;

// Projection and Model View matrices
MATRIX		m_mProjection, m_mView;

// Array to lookup the textures for each material in the scene
GLuint*			m_puiTextures;

// Variables to handle the animation in a time-based manner
int				m_iTimePrev;
VERTTYPE		m_fFrame;
float       m_AvgFramerate;

int frames = 0;

#define DEMO_FRAME_RATE	(1.0f / 30.0f)

// allocate in heap
CDisplayText * AppDisplayText;
CTexture * Textures;

// Vertex Buffer Object (VBO) handles
GLuint*	m_puiVbo;
GLuint*	m_puiIndexVbo;

// function definitions
void CameraGetMatrix();
void ComputeViewMatrix();
void LoadMaterial(int i32Index);
void LoadVbos();
void DrawModel();

bool CShell::InitApplication()
{
   AppDisplayText = new CDisplayText;    
	Textures = new CTexture;
  	
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
	sprintf(filename, "%s/model_float.pod", buffer);
	if(!m_Scene->ReadFromFile(filename))
	    return false;
	    

	// Initialize variables used for the animation
	m_fFrame = 0;
	m_iTimePrev = 0;
	m_AvgFramerate = 0;

    memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Mallet.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32MalletTexture))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

   // Init DisplayText
	if(!AppDisplayText->SetTextures(WindowHeight, WindowWidth))
	{
		fprintf(stderr, "ERROR: Cannot initialise AppDisplayText\n");
                return false;
	}

	/* Model View Matrix */
	CameraGetMatrix();

	/* Projection Matrix */
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glMultMatrixf(m_mProjection.f);
   
  	/* Enables Depth Testing */
	glEnable(GL_DEPTH_TEST);

	/* Enables Smooth Colour Shading */
	glShadeModel(GL_SMOOTH);

	/* Enable texturing */
	glEnable(GL_TEXTURE_2D);

	/* Define front faces */
	glFrontFace(GL_CW);

	/* Enables texture clamping */
	glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
	glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
   
   /* Reset the model view matrix to position the light */
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

   /* Setup ambiant light */
   glEnable(GL_LIGHTING);
   VERTTYPE lightGlobalAmbient[] = {f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f)};
   glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lightGlobalAmbient);

   /* Setup a directional light source */
   VERTTYPE lightPosition[] = {f2vt(-0.7f), f2vt(-1.0f), f2vt(+0.2f), f2vt(0.0f)};
   VERTTYPE lightAmbient[]  = {f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f)};
   VERTTYPE lightDiffuse[]  = {f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f)};
   VERTTYPE lightSpecular[] = {f2vt(0.2f), f2vt(0.2f), f2vt(0.2f), f2vt(1.0f)};

   glEnable(GL_LIGHT0);
   glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
   glLightfv(GL_LIGHT0, GL_AMBIENT, lightAmbient);
   glLightfv(GL_LIGHT0, GL_DIFFUSE, lightDiffuse);
   glLightfv(GL_LIGHT0, GL_SPECULAR, lightSpecular);
   
   if(!m_iTimePrev)
      m_iTimePrev = GetTimeInMsSince1970();
      
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
	// Frees the texture
	Textures->ReleaseTexture(m_ui32MalletTexture);

	// Frees the memory allocated for the scene
	m_Scene->Destroy();
	
	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;
	delete Textures;
	delete m_Scene;
	
	delete[] m_puiVbo;
	delete[] m_puiIndexVbo;
	
	return true;
}

bool CShell::UpdateScene()
{
	// Sets the clear color
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// TODO: try backface culling
	glDisable(GL_CULL_FACE);
	
	return true;
}

bool CShell::RenderScene()
{
	/*
		Calculates the frame number to animate in a time-based manner.
	*/
	int iTime = GetTimeInMsSince1970();
   //int iTime = GetTimeInMs();

	int iDeltaTime = iTime - m_iTimePrev;
	m_iTimePrev	= iTime;

	m_fFrame	+= iDeltaTime * 0.03f; // * DEMO_FRAME_RATE;

	while(m_fFrame > m_Scene->nNumFrame-1)
		m_fFrame -= m_Scene->nNumFrame-1;
   
   /* Clear the depth and frame buffer */
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
   
	/* Set Z compare properties */
	glEnable(GL_DEPTH_TEST);

	/* Disable Blending*/
	glDisable(GL_BLEND);

	/* Calculate the model view matrix */
	glMatrixMode(GL_MODELVIEW);
	glLoadMatrixf(m_mView.f);

   // Draw the model
   DrawModel();
	
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
		m_AvgFramerate = ((float)frames/(TimeInterval));
	
	AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "fps: %3.2f", m_AvgFramerate);

	// show text on the display
	AppDisplayText->DisplayDefaultTitle("Matrix Palette", "", eDisplayTextLogoIMG);

	AppDisplayText->Flush();	
	
	return true;
}


/*******************************************************************************
 * Function Name  : LoadMaterial
 * Input		  : index into the material list
 * Description    : Loads the material index
 *******************************************************************************/
void LoadMaterial(int index)
{
	/*
		Load the model's material
	*/
	SPODMaterial* mat = &m_Scene->pMaterial[index];

	glBindTexture(GL_TEXTURE_2D, m_ui32MalletTexture);

	VERTTYPE prop[4];
	int i;
	prop[3] = f2vt(1.0f);

	for (i=0; i<3; ++i)
		prop[i] = mat->pfMatAmbient[i];

	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, prop);

	for (i=0; i<3; ++i)
		prop[i] = mat->pfMatDiffuse[i];

	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, prop);

	for (i=0; i<3; ++i)
		prop[i] = mat->pfMatSpecular[i];

	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, prop);
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, mat->fMatShininess);
}


/*******************************************************************************
 * Function Name  : DrawModel
 * Description    : Draws the model
 *******************************************************************************/
void DrawModel()
{
   int err;

	//Set the frame number
	m_Scene->SetFrame(m_fFrame);

	//Iterate through all the mesh nodes in the scene
	for(int iNode = 0; iNode < (int)m_Scene->nNumMeshNode; ++iNode)
	{
		//Get the mesh node.
		SPODNode* pNode = &m_Scene->pNode[iNode];

		//Get the mesh that the mesh node uses.
		SPODMesh* pMesh = &m_Scene->pMesh[pNode->nIdx];

		// bind the VBO for the mesh
		glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[pNode->nIdx]);

		// bind the index buffer, won't hurt if the handle is 0
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[pNode->nIdx]);

		//Load the material that belongs to the mesh node.
		LoadMaterial(pNode->nIdxMaterial);

		//If the mesh has bone weight data then we must be skinning.
		bool bSkinning = pMesh->sBoneWeight.pData != 0;

		// If the mesh is used for skining then set up the matrix palettes.
		if(bSkinning)
		{
			//Enable the matrix palette extension
			glEnable(GL_MATRIX_PALETTE_OES);
                        if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);

			/*
				Enables the matrix palette stack extension, and apply subsequent
				matrix operations to the matrix palette stack.
			*/
			glMatrixMode(GL_MATRIX_PALETTE_OES);
                        if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);

			MATRIX	mBoneWorld;
			int			i32NodeID;

			/*
				Iterate through all the bones in the batch
			*/
			for(int j = 0; j < pMesh->sBoneBatches.pnBatchBoneCnt[0]; ++j)
			{
				/*
					Set the current matrix palette that we wish to change. An error
					will be returned if the index (j) is not between 0 and
					GL_MAX_PALETTE_MATRICES_OES. The value of GL_MAX_PALETTE_MATRICES_OES
					can be retrieved using glGetIntegerv, the initial value is 9.

					GL_MAX_PALETTE_MATRICES_OES does not mean you need to limit
					your character to 9 bones as you can overcome this limitation
					by using bone batching which splits the mesh up into sub-meshes
					which use only a subset of the bones.
				*/

                                glCurrentPaletteMatrixOES(j);
                                if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);

				// Generates the world matrix for the given bone in this batch.
				i32NodeID = pMesh->sBoneBatches.pnBatches[j];
				m_Scene->GetBoneWorldMatrix(mBoneWorld, *pNode, m_Scene->pNode[i32NodeID]);

				// Multiply the bone's world matrix by the view matrix to put it in view space
				MatrixMultiply(mBoneWorld, mBoneWorld, m_mView);

				// Load the bone matrix into the current palette matrix.
				glLoadMatrixf(mBoneWorld.f);
			}
		}
		else
		{
			//If we're not skinning then disable the matrix palette.
			glDisable(GL_MATRIX_PALETTE_OES);
                        if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);
		}

		//Switch to the modelview matrix.
		glMatrixMode(GL_MODELVIEW);
		//Push the modelview matrix
		glPushMatrix();

		//Get the world matrix for the mesh and transform the model view matrix by it.
		MATRIX worldMatrix;
		m_Scene->GetWorldMatrix(worldMatrix, *pNode);
		glMultMatrixf(worldMatrix.f);

		/* Modulate with vertex color */
		glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

		/* Enable lighting */
		glEnable(GL_LIGHTING);

		/* Enable back face culling */
		glDisable(GL_CULL_FACE);
		glCullFace(GL_FRONT);

		/* Enable States */
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_NORMAL_ARRAY);
                if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);

		// If the mesh has uv coordinates then enable the texture coord array state
		if (pMesh->psUVW)
			glEnableClientState(GL_TEXTURE_COORD_ARRAY);

		if(bSkinning)
		{
			//If we are skinning then enable the relevant states.
			glEnableClientState(GL_MATRIX_INDEX_ARRAY_OES);
			glEnableClientState(GL_WEIGHT_ARRAY_OES);
                  if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);

		}

		/* Set Data Pointers */
		// Used to display non interleaved geometry
		glVertexPointer(pMesh->sVertex.n, VERTTYPEENUM, pMesh->sVertex.nStride, pMesh->sVertex.pData);
		glNormalPointer(VERTTYPEENUM, pMesh->sNormals.nStride, pMesh->sNormals.pData);
                if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);

		if (pMesh->psUVW)
			glTexCoordPointer(pMesh->psUVW[0].n, VERTTYPEENUM, pMesh->psUVW[0].nStride, pMesh->psUVW[0].pData);

                if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);

		if(bSkinning)
		{
			//Set up the indexes into the matrix palette.
			glMatrixIndexPointerOES(pMesh->sBoneIdx.n, GL_UNSIGNED_BYTE, pMesh->sBoneIdx.nStride, pMesh->sBoneIdx.pData);
			glWeightPointerOES(pMesh->sBoneWeight.n, VERTTYPEENUM, pMesh->sBoneWeight.nStride, pMesh->sBoneWeight.pData);
                        if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);
		}

		// Draw

		// Indexed Triangle list
		glDrawElements(GL_TRIANGLES, pMesh->nNumFaces*3, GL_UNSIGNED_SHORT, 0);

		/* Disable States */
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_NORMAL_ARRAY);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);

		if(bSkinning)
		{
			glDisableClientState(GL_MATRIX_INDEX_ARRAY_OES);
			glDisableClientState(GL_WEIGHT_ARRAY_OES);
                        if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);
		}

		//Reset the modelview matrix back to what it was before we transformed by the mesh node.
		glPopMatrix();
               if((err = glGetError()) != GL_NO_ERROR) printf("gl error at %s : %i\n", __FILE__, __LINE__);
	}

	//We are finished with the matrix pallete so disable it.
	glDisable(GL_MATRIX_PALETTE_OES);

	// unbind the vertex buffers as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

// MARK: -
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

	//Set the Up Vector
	vUp.x = f2vt(0.0f);
	vUp.y = f2vt(1.0f);
	vUp.z = f2vt(0.0f);

	//If the scene contains a camera then...
	if(m_Scene->nNumCamera)
	{
		//.. get the Camera's position, direction and FOV.
		fFOV = m_Scene->GetCameraPos(vFrom, vTo, 0);
		/*
		Convert the camera's field of view from horizontal to vertical
		(the 0.75 assumes a 4:3 aspect ratio).
		*/
		fFOV = VERTTYPEMUL(fFOV, WindowHeight/WindowWidth);
	}
	else
	{
		fFOV = VERTTYPEMUL(M_PI, f2vt(0.16667f));
	}

	/* Set up the view matrix */
	MatrixLookAtRH(m_mView, vFrom, vTo, vUp);

	/* Set up the projection matrix */
   MatrixPerspectiveFovRH(m_mProjection, fFOV, f2vt(WindowHeight/WindowWidth), f2vt(CAM_NEAR), f2vt(CAM_FAR), true);
}
