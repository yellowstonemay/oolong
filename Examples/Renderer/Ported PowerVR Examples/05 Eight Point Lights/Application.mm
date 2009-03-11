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
#include "Geometry.h"
#include "UI.h"
#include "App.h"
#include "MemoryManager.h"
#include "Macros.h"
#include "Pathes.h"

#include <stdio.h>
#include <sys/time.h>



CDisplayText * AppDisplayText;
CTexture * Texture;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

int frames;
float frameRate;

/****************************************************************************
 ** Defines
 ****************************************************************************/
const unsigned int g_ui32LightNo = 8;

/****************************************************************************
 ** Structures
 ****************************************************************************/
struct SLightVars
{
	Vec4	Position;	// GL_LIGHT_POSITION
	Vec4	Direction;	// GL_SPOT_DIRECTION
	Vec4	Ambient;	// GL_AMBIENT
	Vec4	Diffuse;	// GL_DIFFUSE
	Vec4	Specular;	// GL_SPECULAR
	
	Vec3	vRotationStep;
	Vec3	vRotationCentre;
	Vec3	vRotation;
	Vec3	vPosition;
};



/* Light properties */
SLightVars m_psLightData[8];
#define WIDTH 320
#define HEIGHT 480

// 3D Model
CPVRTModelPOD	*m_Scene;
CTexture * Textures;

// OpenGL handles for textures and VBOs
GLuint m_ui32Stone;
GLuint m_ui32Light;

GLuint*	m_puiVbo;
GLuint*	m_puiIndexVbo;

/* Number of frames */
long m_nNumFrames;
GLuint*	m_pui32Textures;


/****************************************************************************
 ** Function Definitions
 ****************************************************************************/
void InitLight(SLightVars &Light);
void StepLight(SLightVars &Light);
void DrawLight(SLightVars &Light);
void LoadVbos();
//bool LoadTextures(String* const pErrorStr);
void DrawMesh(unsigned int ui32MeshID);



bool CShell::InitApplication()
{
	AppDisplayText = new CDisplayText;  
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
				printf("Display text textures loaded\n");
				
	m_Scene = (CPVRTModelPOD*)malloc(sizeof(CPVRTModelPOD));
	memset(m_Scene, 0, sizeof(CPVRTModelPOD));
	
	Textures = (CTexture*)malloc(sizeof(CTexture));
	memset(Textures, 0, sizeof(CTexture));

	
	/*
	 Loads the scene from the .pod file into a CPVRTModelPOD object.
	 We could also export the scene as a header file and
	 load it with ReadFromMemory().
	 */
	char *buffer = new char[2048];
	GetResourcePathASCII(buffer, 2048);
	
	/* Gets the Data Path */
	char		*filename = new char[2048];
	sprintf(filename, "%s/LightingScene_float.pod", buffer);
	if(m_Scene->ReadFromFile(filename)!= TRUE)
		return false;

	MATRIX	MyPerspMatrix;
	int			i;
	
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Stone.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32Stone))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/LightTex.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32Light))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	//	Initialize VBO data
	LoadVbos();
	
	// Setup all materials
	VERTTYPE Ambient[]	= {f2vt(0.1f), f2vt(0.1f), f2vt(0.1f), f2vt(1.0f)};
	VERTTYPE Diffuse[]	= {f2vt(0.5f), f2vt(0.5f), f2vt(0.5f), f2vt(1.0f)};
	VERTTYPE Specular[]	= {f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f)};

	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, Ambient);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, Diffuse);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, Specular);
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, f2vt(10.0f));	// Nice and shiny so we don't get aliasing from the 1/2 angle

	// Initialize all lights
	srand(0);
	for(i = 0; i < 8; ++i)
		InitLight(m_psLightData[i]);
	
	/* Perspective matrix */
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	MatrixPerspectiveFovRH(MyPerspMatrix, f2vt(20.0f*(PIf/180.0f)), f2vt((float)WIDTH / (float)HEIGHT), f2vt(10.0f), f2vt(1200.0f), true);
	glMultMatrixf(MyPerspMatrix.f);
	
	/* Modelview matrix */
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(f2vt(0.0f), f2vt(0.0f), f2vt(-500.0f));
	
	/* Setup culling */
	glEnable(GL_CULL_FACE);
	glFrontFace(GL_CW);
	glCullFace(GL_FRONT);
	
	/* Enable texturing */
	glEnable(GL_TEXTURE_2D);
	
	/*
		Build an array to map the textures within the pod file
		to the textures we loaded earlier.
	*/

	m_pui32Textures = new GLuint[m_Scene->nNumMaterial];

	for(i = 0; i < (int) m_Scene->nNumMaterial; ++i)
	{
		m_pui32Textures[i] = 0;
		SPODMaterial* pMaterial = &m_Scene->pMaterial[i];

		if(!strcmp(pMaterial->pszName, "Stone"))
			m_pui32Textures[i] = m_ui32Stone;
	}

	// Set the clear colour
	glClearColor(f2vt(0.0f), f2vt(0.0f), f2vt(0.0f), f2vt(1.0f));
	
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
	
	// Free the memory allocated for the scene
	m_Scene->Destroy();

	delete[] m_puiVbo;
	delete[] m_puiIndexVbo;
	
	// Frees the texture
	Textures->ReleaseTexture(m_ui32Stone);
	Textures->ReleaseTexture(m_ui32Light);
	
	free(Textures);
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
	
	AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "fps: %3.2f", frameRate);
	
	return true;
}


bool CShell::RenderScene()
{
	unsigned int i;
	MATRIX		RotationMatrix;
	
	/* Set up viewport */
//	glViewport(0, 0, WIDTH, HEIGHT);
	
	/* Clear the buffers */
	glEnable(GL_DEPTH_TEST);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	/* Lighting */
	
	/* Enable lighting (needs to be specified everyframe as Print3D will turn it off */
	glEnable(GL_LIGHTING);
	
	/* Increase number of frames */
	m_nNumFrames++;
	m_nNumFrames = m_nNumFrames % 3600;
	MatrixRotationY(RotationMatrix, f2vt((-m_nNumFrames*0.1f) * PIf/180.0f));
	
	/* Loop through all lights */
	for(i = 0; i < 8; ++i)
	{
		// Only process lights that we are actually using
		if(i < g_ui32LightNo)
		{
			/* Transform light */
			StepLight(m_psLightData[i]);
			
			/* Set light properties */
			glLightfv(GL_LIGHT0 + i, GL_POSITION, &m_psLightData[i].Position.x);
			glLightfv(GL_LIGHT0 + i, GL_AMBIENT, &m_psLightData[i].Ambient.x);
			glLightfv(GL_LIGHT0 + i, GL_DIFFUSE, &m_psLightData[i].Diffuse.x);
			glLightfv(GL_LIGHT0 + i, GL_SPECULAR, &m_psLightData[i].Specular.x);
			
			/* Enable light */
			glEnable(GL_LIGHT0 + i);
		}
		else
		{
			/* Disable remaining lights */
			glDisable(GL_LIGHT0 + i);
		}
	}
	
	/*************
	 * Begin Scene
	 *************/
	
	// Enable client states
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		
	// Save matrix by pushing it on the stack
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	
	/* Add a small Y rotation to the model */
	glMultMatrixf(RotationMatrix.f);
	
	// Loop through and draw all meshes
	for(i = 0; i < m_Scene->nNumMeshNode; ++i)
	{
		SPODNode& Node = m_Scene->pNode[i];

		// Loads the correct texture using our texture lookup table
		glBindTexture(GL_TEXTURE_2D, m_pui32Textures[Node.nIdxMaterial]);

		DrawMesh(Node.nIdx);
	}
	
	// Disable normals as the light quads do not have any
	glDisableClientState(GL_NORMAL_ARRAY);

	// Restore matrix
	glPopMatrix();
	
	// draw lights

	// No lighting for lights
	glDisable(GL_LIGHTING);
	
	/* Disable Z writes */
	glDepthMask(GL_FALSE);
	
	/* Set additive blending */
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE,GL_ONE);
	
	// Set texture and texture environment
	glBindTexture(GL_TEXTURE_2D, m_ui32Light);

	// Render all lights in use
	for(i = 0; i < g_ui32LightNo; ++i)
		DrawLight(m_psLightData[i]);
	
	/* Disable blending */
	glDisable(GL_BLEND);
	
	/* Restore Z writes */
	glDepthMask(GL_TRUE);
	
	// Disable client states
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// show text on the display
	AppDisplayText->DisplayDefaultTitle("Eight Point Lights", "", eDisplayTextLogoIMG);
	
	AppDisplayText->Flush();	
	
	return true;
}

/*******************************************************************************
 * Function Name  : initLight
 * Inputs		  : *pLight
 * Description    : Initialize light structure
 *******************************************************************************/
void InitLight(SLightVars &pLight)
{
	/* Light ambient colour */
	pLight.Ambient.x = f2vt(0.0);
	pLight.Ambient.y = f2vt(0.0);
	pLight.Ambient.z = f2vt(0.0);
	pLight.Ambient.w = f2vt(1.0);
	
	/* Light Diffuse colour */
	double difFac = 0.4;
	pLight.Diffuse.x = f2vt((float)( difFac * (rand()/(double)RAND_MAX) ) * 2.0f); //1.0;
	pLight.Diffuse.y = f2vt((float)( difFac * (rand()/(double)RAND_MAX) ) * 2.0f); //1.0;
	pLight.Diffuse.z = f2vt((float)( difFac * (rand()/(double)RAND_MAX) ) * 2.0f); //1.0;
	pLight.Diffuse.w = f2vt((float)( 1.0 ));
	
	/* Light Specular colour */
	double specFac = 0.1;
	pLight.Specular.x = f2vt((float)( specFac * (rand()/(double)RAND_MAX) ) * 2.0f); //1.0;
	pLight.Specular.y = f2vt((float)( specFac * (rand()/(double)RAND_MAX) ) * 2.0f); //1.0;
	pLight.Specular.z = f2vt((float)( specFac * (rand()/(double)RAND_MAX) ) * 2.0f); //1.0;
	pLight.Specular.w = f2vt((float)( 1.0 ));
	
	/* Randomize some of the other parameters */
	float lightDist = 80.0f;
	pLight.vPosition.x = f2vt((float)((rand()/(double)RAND_MAX) * lightDist/2.0f ) + lightDist/2.0f);
	pLight.vPosition.y = f2vt((float)((rand()/(double)RAND_MAX) * lightDist/2.0f ) + lightDist/2.0f);
	pLight.vPosition.z = f2vt((float)((rand()/(double)RAND_MAX) * lightDist/2.0f ) + lightDist/2.0f);
	
	float rStep = 2;
	pLight.vRotationStep.x = f2vt((float)( rStep/2.0 - (rand()/(double)RAND_MAX) * rStep ));
	pLight.vRotationStep.y = f2vt((float)( rStep/2.0 - (rand()/(double)RAND_MAX) * rStep ));
	pLight.vRotationStep.z = f2vt((float)( rStep/2.0 - (rand()/(double)RAND_MAX) * rStep ));
	
	pLight.vRotation.x = f2vt(0.0f);
	pLight.vRotation.y = f2vt(0.0f);
	pLight.vRotation.z = f2vt(0.0f);
	
	pLight.vRotationCentre.x = f2vt(0.0f);
	pLight.vRotationCentre.y = f2vt(0.0f);
	pLight.vRotationCentre.z = f2vt(0.0f);
}

/*******************************************************************************
 * Function Name  : stepLight
 * Inputs		  : *pLight
 * Description    : Advance one step in the light rotation.
 *******************************************************************************/
void StepLight(SLightVars &pLight)
{
	MATRIX RotationMatrix, RotationMatrixX, RotationMatrixY, RotationMatrixZ;
	
	/* Increase rotation angles */
	pLight.vRotation.x += pLight.vRotationStep.x;
	pLight.vRotation.y += pLight.vRotationStep.y;
	pLight.vRotation.z += pLight.vRotationStep.z;
	
	while(pLight.vRotation.x > f2vt(360.0f)) pLight.vRotation.x -= f2vt(360.0f);
	while(pLight.vRotation.y > f2vt(360.0f)) pLight.vRotation.y -= f2vt(360.0f);
	while(pLight.vRotation.z > f2vt(360.0f)) pLight.vRotation.z -= f2vt(360.0f);
	
	/* Create three rotations from rotation angles */
	MatrixRotationX(RotationMatrixX, VERTTYPEMUL(pLight.vRotation.x, f2vt(PIf/180.0f)));
	MatrixRotationY(RotationMatrixY, VERTTYPEMUL(pLight.vRotation.y, f2vt(PIf/180.0f)));
	MatrixRotationZ(RotationMatrixZ, VERTTYPEMUL(pLight.vRotation.z, f2vt(PIf/180.0f)));
	
	/* Build transformation matrix by concatenating all rotations */
	MatrixMultiply(RotationMatrix, RotationMatrixY, RotationMatrixZ);
	MatrixMultiply(RotationMatrix, RotationMatrixX, RotationMatrix);
	
	/* Transform light with transformation matrix, setting w to 1 to indicate point light */
	TransTransformArray((VECTOR3*)&pLight.Position, &pLight.vPosition, 1, &RotationMatrix);
	pLight.Position.w = f2vt(1.0f);
}

/*******************************************************************************
 * Function Name  : renderLight
 * Inputs		  : *pLight
 * Description    : Draw every light as a quad.
 *******************************************************************************/
void DrawLight(SLightVars &Light)
{
	VERTTYPE	quad_verts[4 * 4];
	
	// Set Quad UVs
	VERTTYPE	quad_uvs[2 * 4] = {f2vt(0), f2vt(0),
								   f2vt(1), f2vt(0),
								   f2vt(0), f2vt(1),
								   f2vt(1), f2vt(1)};
	
	VERTTYPE	fLightSize = f2vt(5.0f);
	
	// Set quad vertices
	quad_verts[0]  = Light.Position.x - fLightSize;
	quad_verts[1]  = Light.Position.y - fLightSize;
	quad_verts[2]  = Light.Position.z;
	
	quad_verts[3]  = Light.Position.x + fLightSize;
	quad_verts[4]  = Light.Position.y - fLightSize;
	quad_verts[5]  = Light.Position.z;
	
	quad_verts[6]  = Light.Position.x - fLightSize;
	quad_verts[7]  = Light.Position.y + fLightSize;
	quad_verts[8]  = Light.Position.z;
	
	quad_verts[9]  = Light.Position.x + fLightSize;
	quad_verts[10] = Light.Position.y + fLightSize;
	quad_verts[11] = Light.Position.z;
	
	// Set data
	glVertexPointer(3, VERTTYPEENUM, 0, quad_verts);
	glTexCoordPointer(2, VERTTYPEENUM, 0, quad_uvs);
	
	// Set light colour 2x overbright for more contrast (will be modulated with texture)
	glColor4f(VERTTYPEMUL(Light.Diffuse.x, f2vt(2.0f)), VERTTYPEMUL(Light.Diffuse.y,f2vt(2.0f)), VERTTYPEMUL(Light.Diffuse.z,f2vt(2.0f)), f2vt(1));
	
	/* Draw quad */
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
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
	glNormalPointer(VERTTYPEENUM, Mesh.sNormals.nStride, Mesh.sNormals.pData);
	glTexCoordPointer(2, VERTTYPEENUM, Mesh.psUVW[0].nStride, Mesh.psUVW[0].pData);
	
	glDrawElements(GL_TRIANGLES, Mesh.nNumFaces * 3, GL_UNSIGNED_SHORT, 0);
	
	// unbind the vertex buffers as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}
