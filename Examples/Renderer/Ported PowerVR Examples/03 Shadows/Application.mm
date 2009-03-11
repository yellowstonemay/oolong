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


/******************************************************************************
 Defines
 ******************************************************************************/
#define	CHARWIDTH	45.0f	// Used to draw the basic blob shadow
#define FLOORHEIGHT 0.5f
#define FLOORSIZE 800

// Camera constants. Used for making the projection matrix
#define CAM_NEAR	10.0f
#define CAM_FAR		1000.0f

#define TEXTURESIZE 256

#define WIDTH 480
#define HEIGHT 320

#define TIME_FPS_UPDATE		(1)

enum ESceneObjects
{
	eGround,
	eLight,
	eShadowCaster
};

enum ShadowModes
{
	BASEBLOBMODE,
	ADVANCEDBLOBMODE,
	PROJGEOMMODE,
	R2TEXMODE
};

// Texture handle
GLuint m_uiTableCover, m_uiKettle, m_uiBlobMap, m_uiShadow;

// VBO Handles
GLuint*	m_puiVbo;
GLuint*	m_puiIndexVbo;

// 3D Model
CPVRTModelPOD *m_Scene;

// Projection and Model View matrices
MATRIX m_mProjection, m_mView;

// Array to lookup the textures for each material in the scene
GLuint*	m_puiTextures;

VECTOR3 m_vLightPos;

MATRIX	m_mfloorShadow;
MATRIX  m_mLightView;
MATRIX	m_mObjectRotation;

VECTOR4 m_fPlane;
VECTOR3 m_fObjectCentre;
unsigned int m_ui32Mode;

VERTTYPE m_fAngle;
VERTTYPE m_fObjectAngle;

// FPS variables
float m_fFPS;

CDisplayText * AppDisplayText;
CTexture * Textures;

int frames;

bool DrawShadowTexture();
void DrawMesh(SPODNode* pNode, bool bProjectTexture = false);
void DrawBaseBlob(VECTOR3 fCentre);
void DrawAdvancedBlobShadow();
void shadowMatrix(MATRIX &shadowMat, const VECTOR4 &vPlane, const VECTOR4 &vlightPos);
void findPlane(VECTOR4 &plane, const VECTOR3 &v0, const VECTOR3 &v1, const VECTOR3 &v2);
void DrawProjectedShadow(SPODNode* pNode);
bool RenderToTexture(SPODNode *pNode);
bool RenderFromLightsView();
void LoadVbos();

bool CShell::InitApplication()
{
	AppDisplayText = new CDisplayText;  
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
		printf("Display text textures loaded\n");

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
	sprintf(filename, "%s/Scene_float.pod", buffer);
	if(m_Scene->ReadFromFile(filename) != true)
		return false;

	// The cameras are stored in the file. We check it contains at least one.
	if(m_Scene->nNumCamera == 0)
		return false;

	m_fAngle = f2vt(0);
	m_fFPS = 0;
	
        m_puiVbo = 0;
        m_puiIndexVbo = 0;
	
	/*
	 Start the demo with the advanced blob
	 */
	m_ui32Mode = BASEBLOBMODE;

	// Enables texturing
	glEnable(GL_TEXTURE_2D);
	
        //	Initialize VBO data 
	LoadVbos();
	
	/*
	 Load the textures from the headers.
	 */
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/TableCover.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_uiTableCover))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Kettle.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_uiKettle))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/Blob.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_uiBlobMap))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	

	
	/*
	 Generate a texture for the render to texture shadow.
	 */
	glGenTextures(1,&m_uiShadow);
	
	// Bind and Enable Texture ID
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D,m_uiShadow);
	glEnable(GL_TEXTURE_2D);
	
	// If Tex Params are not set glCopyTexImage2D will fail !
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	// Initialise the Texture
	glTexImage2D(GL_TEXTURE_2D,0,GL_RGB,TEXTURESIZE,TEXTURESIZE,0,GL_RGB,GL_UNSIGNED_BYTE,0);
	
	// Enables lighting. See BasicTnL for a detailed explanation
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	
	VECTOR3	vFrom, vTo, vUp;
	
	vUp.x = f2vt(0.0f);
	vUp.y = f2vt(1.0f);
	vUp.z = f2vt(0.0f);
	
	// We can get the camera position, target and field of view (fov) with GetCameraPos()
	m_Scene->GetCameraPos( vFrom, vTo, 0);
	
	MatrixLookAtRH(m_mView, vFrom, vTo, vUp);
	
	// Calculates the projection matrix
	MatrixPerspectiveFovRH(m_mProjection, f2vt(45), f2vt((float)HEIGHT/(float)WIDTH), f2vt(CAM_NEAR), f2vt(CAM_FAR), true);
	
	// Reads the light direction from the scene.
	VECTOR4 vLightDirection;
	MATRIX mWorld;
	
	/*
	 Set the light direction using the position of one of the meshes.
	 */
	SPODNode* pNode;
	
	pNode = &m_Scene->pNode[eLight];
	m_Scene->GetWorldMatrix(mWorld, *pNode);
	
	MATRIX fRot;
	MatrixRotationY(fRot, m_fAngle);
	MatrixMultiply(mWorld, mWorld, fRot);
	
	vLightDirection.x = m_vLightPos.x = mWorld.f[12];
	vLightDirection.y = m_vLightPos.y = mWorld.f[13];
	vLightDirection.z = m_vLightPos.z = mWorld.f[14];
	vLightDirection.w = f2vt(0.0f);
	
	// Specify the light direction in world space
	glLightfv(GL_LIGHT0, GL_POSITION, (VERTTYPE*)&vLightDirection);
	
	glShadeModel( GL_SMOOTH );
	
	/*
	 Build an array to map the textures within the pod header files
	 to the textures we loaded a bit further up.
	 */
	m_puiTextures = new GLuint[m_Scene->nNumMaterial];
	
	for(unsigned int i = 0; i < m_Scene->nNumMaterial; ++i)
	{
		m_puiTextures[i] = 0;
		SPODMaterial* pMaterial = &m_Scene->pMaterial[i];
		
		if(!strcmp(pMaterial->pszName, "Material #1"))
			m_puiTextures[i] = m_uiTableCover;
		else if(!strcmp(pMaterial->pszName, "Material #2"))
			m_puiTextures[i] = m_uiKettle;
	}
	
	glEnable(GL_DEPTH_TEST);
	
	/*
	 Get the centre of the mesh that I have called the shadow caster.
	 This is used for the advanced blob.
	 */
	pNode = &m_Scene->pNode[eShadowCaster];
	SPODMesh* pMesh = &m_Scene->pMesh[pNode->nIdx];
	
	m_fObjectCentre.x = f2vt(0.0f);
	m_fObjectCentre.y = f2vt(5.0f);
	m_fObjectCentre.z = f2vt(0.0f);
	
	/*
	 Get the plane for the ground mesh. Obviously this relys on the
	 ground being flat.
	 */
	pNode = &m_Scene->pNode[eGround];
	pMesh = &m_Scene->pMesh[pNode->nIdx];
	
	VECTOR3* pVertices = (VECTOR3*) (pMesh->pInterleaved + (size_t) pMesh->sVertex.pData);
	
	/* Setup floor plane for projected shadow calculations. */
	findPlane(m_fPlane, pVertices[0] , pVertices[1], pVertices[2]);
	
	m_fFPS = 0;
		
	m_fObjectAngle = f2vt(0);
	MatrixIdentity(m_mObjectRotation);
	
	// polygon offset for shadow to avoid ZFighting between the shadow and floor
	glPolygonOffset(f2vt(-10.0f),f2vt(-25.0f));
	
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

/*******************************************************************************
 * Function Name  : findPlane
 * Inputs		  : 3 Points
 * Outputs		  : Plane Equations
 * Description    : Find the plane equation given 3 points.
 *******************************************************************************/
void findPlane(VECTOR4 &plane, const VECTOR3 &v0, const VECTOR3 &v1, const VECTOR3 &v2)
{
	VECTOR3 vec0, vec1;
	
	/* Need 2 vectors to find cross product. */
	vec0.x = v1.x - v0.x;
	vec0.y = v1.y - v0.y;
	vec0.z = v1.z - v0.z;
	
	MatrixVec3Normalize(vec0, vec0);
	
	vec1.x = v2.x - v0.x;
	vec1.y = v2.y - v0.y;
	vec1.z = v2.z - v0.z;
	
	MatrixVec3Normalize(vec1, vec1);
	
	/* find cross product to get A, B, and C of plane equation */
	plane.x = VERTTYPEMUL(vec0.y, vec1.z)   - VERTTYPEMUL(vec0.z, vec1.y);
	plane.y = -(VERTTYPEMUL(vec0.x, vec1.z) - VERTTYPEMUL(vec0.z, vec1.x));
	plane.z = VERTTYPEMUL(vec0.x, vec1.y)   - VERTTYPEMUL(vec0.y, vec1.x);
	
	plane.w = -(VERTTYPEMUL(plane.x, v0.x) + VERTTYPEMUL(plane.y, v0.y) + VERTTYPEMUL(plane.z, v0.z));
}



bool CShell::QuitApplication()
{
	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;
	
	// Frees the texture lookup array
	delete[] m_puiTextures;
	
	// Frees the texture
	Textures->ReleaseTexture(m_uiKettle);
	Textures->ReleaseTexture(m_uiTableCover);
		
	glDeleteTextures(1, &m_uiShadow);
	
	delete[] m_puiVbo;
	delete[] m_puiIndexVbo;

	// Frees the memory allocated for the scene
	m_Scene->Destroy();
	
	delete Textures;

	return true;
}

/*!****************************************************************************
 @Function		RenderToTexture
 @Return		bool		true if no error occured
 @Description	Renders the mesh in pNode to texture from the cameras point
 of view.
 ******************************************************************************/
bool RenderToTexture(SPODNode *pNode)
{
	MATRIX mWorld;
	MATRIX mModelView;
	
	// Gets the node model matrix
	m_Scene->GetWorldMatrix(mWorld, *pNode);
	
	// Set the Shadow Color and Alpha
	glColor4f(f2vt(0.25f), f2vt(0.25f), f2vt(0.25f), f2vt(0.0f));
	
	MatrixMultiply(mWorld, mWorld, m_mObjectRotation);
	
	// Multiply the view matrix by the model (mWorld) matrix to get the model-view matrix
	glMatrixMode(GL_MODELVIEW);
	
	MatrixMultiply(mModelView, mWorld, m_mLightView);
	glLoadMatrixf(mModelView.f);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	
	glDisable(GL_TEXTURE_2D);
	
	glDisable(GL_CULL_FACE);
	
	DrawMesh(pNode);
	
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, m_uiShadow);
	
	/* If we are not using PBuffers copy the backbuffer into the texture. */
	glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, TEXTURESIZE, TEXTURESIZE, 0);
	
	glEnable(GL_CULL_FACE);
	return true;
}

/*!****************************************************************************
 @Function		DrawShadowTexture
 @Return		bool		true if no error occured
 @Description	Draws the texture that has been rendered to for the shadow.
 ******************************************************************************/
bool DrawShadowTexture()
{
	glPushMatrix();
	glDisable(GL_DEPTH_TEST);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	float fScale = HEIGHT / WIDTH;
	
	if(1)
	{
		fScale = WIDTH / HEIGHT;
		glRotatef(f2vt(90.0f), f2vt(0),f2vt(0),f2vt(1));
	}
	
	glTranslatef(f2vt(-1), f2vt(-1), f2vt(0.5f));
	glScalef(f2vt(fScale),f2vt(1) ,f2vt(1));
	
	static VERTTYPE	VerticesLeft[] = {
		f2vt(0.02f) , f2vt(0.6f) , f2vt(0.0f),
		f2vt(0.02f) , f2vt(0.02f), f2vt(0.0f),
		f2vt(0.6f)  , f2vt(0.02f), f2vt(0.0f),
		f2vt(0.6f)  , f2vt(0.6f) , f2vt(0.0f),
	};
	
	static VERTTYPE	UVs[] = {
		f2vt(0.0f), f2vt(1.0f),
		f2vt(0.0f), f2vt(0.0f),
		f2vt(1.0f), f2vt(0.0f),
		f2vt(1.0f), f2vt(1.0f)
	};
	
	VERTTYPE *pVertices = ( (VERTTYPE*)&VerticesLeft );
	VERTTYPE *pUV       = ( (VERTTYPE*)&UVs );
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(3,VERTTYPEENUM,0,pVertices);
	
	glClientActiveTexture(GL_TEXTURE0);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glTexCoordPointer(2,VERTTYPEENUM,0,pUV);
	
	glActiveTexture(GL_TEXTURE0);
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, m_uiShadow);
	
	glDrawArrays(GL_TRIANGLE_FAN,0,4);
	
	glDisableClientState(GL_VERTEX_ARRAY);
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glClientActiveTexture(GL_TEXTURE0);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glPopMatrix();
	
	glEnable(GL_DEPTH_TEST);
	return true;
}

/*!****************************************************************************
 @Function		RenderFromLightsView
 @Return		bool		true if no error occured
 @Description	Renders the teapot from the light's view.
 ******************************************************************************/
bool RenderFromLightsView()
{
	glEnable(GL_DEPTH_TEST);
	
	glViewport(0, 0, TEXTURESIZE, TEXTURESIZE);
	glClearColor(f2vt(1), f2vt(1), f2vt(1), f2vt(1));
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	MATRIX proj;
	
	MatrixPerspectiveFovRH(proj, f2vt(45.0f), VERTTYPEDIV(TEXTURESIZE, TEXTURESIZE), f2vt(CAM_NEAR), f2vt(CAM_FAR), false);
	
	glMatrixMode(GL_PROJECTION);
	glLoadMatrixf(proj.f);
	
	RenderToTexture(&m_Scene->pNode[eShadowCaster]);
	
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
	/*
	 If the time and circumstances are right then switch the mode.
	 */
	static CFTimeInterval	startTime = 0;
	CFTimeInterval			TimeInterval;
	
	// calculate our local time
	TimeInterval = CFAbsoluteTimeGetCurrent();
	if(startTime == 0)
		startTime = TimeInterval;
	
	frames++;
	if (TimeInterval - startTime) 
	{
		m_fFPS = ((float)frames/(TimeInterval - startTime));
	}
	
	AppDisplayText->DisplayText(0, 10, 0.4f, RGBA(255,255,255,255), "fps: %3.2f", m_fFPS);
	
	
	bool bUpdateTexture = false;
	
	// five seconds
	if((TimeInterval - startTime) > 5.0f)
	{
		++m_ui32Mode;
		
		if(m_ui32Mode == R2TEXMODE)
			bUpdateTexture = true;
		
		if(m_ui32Mode > R2TEXMODE)
			m_ui32Mode = BASEBLOBMODE;
		
		startTime = TimeInterval;
		frames = 0;
	}

	/*
	 Initialise the viewport and stuff
	 */
	SPODNode* pNode = 0;
	MATRIX mWorld;
	MATRIX mModelView;
	MATRIX fTransform;
	
	/*
	 If the time is right then update the light's angle and the kettle's angle
	 */
	if(TimeInterval > 0.01)
	{
		m_fAngle += f2vt(0.01f);
		//m_ui32Time = ui32Time;
		//	startTime = TimeInterval;
		
		m_fObjectAngle += f2vt(0.009f);
		MatrixIdentity(m_mObjectRotation);
		
		MatrixTranslation(fTransform, 0, f2vt(-21), 0);
		MatrixMultiply(m_mObjectRotation, m_mObjectRotation, fTransform);
		MatrixRotationX(fTransform, -m_fObjectAngle);
		MatrixMultiply(m_mObjectRotation, m_mObjectRotation, fTransform);
		MatrixTranslation(fTransform, 0, f2vt(21), 0);
		MatrixMultiply(m_mObjectRotation, m_mObjectRotation, fTransform);
		
		//Update light position
		VECTOR4 vLightDirection;
		
		pNode = &m_Scene->pNode[eLight];
		
		m_Scene->GetWorldMatrix(mWorld, *pNode);
		
		MatrixRotationY(fTransform, m_fAngle);
		MatrixMultiply(mWorld, mWorld, fTransform);
		
		vLightDirection.x = m_vLightPos.x = mWorld.f[12];
		vLightDirection.y = m_vLightPos.y = mWorld.f[13];
		vLightDirection.z = m_vLightPos.z = mWorld.f[14];
		vLightDirection.w = f2vt(0.0f);
		
		// Specify the light direction in world space
		glLightfv(GL_LIGHT0, GL_POSITION, &vLightDirection.x);
		
		VECTOR3 MyUp, fPointOfInterest;
		
		MyUp.x = f2vt(0.0f);
		MyUp.y = f2vt(1.0f);
		MyUp.z = f2vt(0.0f);
		
		/* The position of the teapot */
		fPointOfInterest.x = f2vt(0.0f);
		fPointOfInterest.y = f2vt(02.0f);
		fPointOfInterest.z = f2vt(0.0f);
		
		/* Model View Matrix */
		MatrixLookAtRH(m_mLightView, m_vLightPos, fPointOfInterest, MyUp);
	}
	
	/*
	 If we are in Render To Texture mode then render the teapot from the light's point of view.
	 */
	if(bUpdateTexture)
	{
		RenderFromLightsView();
		bUpdateTexture = false;
	}
	
	glEnable(GL_DEPTH_TEST);
	glColor4f(f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f));
	
	glViewport(0,0,HEIGHT,WIDTH);
	
	glClearColor(f2vt(0.6f), f2vt(0.8f), f2vt(1.0f), f2vt(1.0f));
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// Loads the projection matrix
	glMatrixMode(GL_PROJECTION);
	glLoadMatrixf(m_mProjection.f);
	
	// Specify the view matrix to OpenGL ES
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glActiveTexture(GL_TEXTURE0);
	glEnable(GL_TEXTURE_2D);
	
	/*
	 Draw the Light
	 */
	glDisable(GL_LIGHTING);
	
	pNode = &m_Scene->pNode[eLight];
	
	m_Scene->GetWorldMatrix(mWorld, *pNode);
	MatrixRotationY(fTransform, m_fAngle);
	MatrixMultiply(mWorld, mWorld, fTransform);
	MatrixMultiply(mModelView, mWorld, m_mView);
	glLoadMatrixf(mModelView.f);
	
	if (pNode->nIdxMaterial == -1)
	{
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, 0);
	}
	else
	{
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, m_puiTextures[pNode->nIdxMaterial]);
	}
	
	DrawMesh(pNode);
	
	/*
	 Draw the ground
	 */
	
	pNode = &m_Scene->pNode[eGround];
	
	m_Scene->GetWorldMatrix(mWorld, *pNode);
	
	MatrixMultiply(mModelView, mWorld, m_mView);
	glLoadMatrixf(mModelView.f);
	
	if (pNode->nIdxMaterial == -1)
	{
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, 0);
	}
	else
	{
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, m_puiTextures[pNode->nIdxMaterial]);
	}
	
	if(m_ui32Mode == R2TEXMODE)
	{
		/*
		 If we are in render to texture mode then draw the ground with the rendered
		 texture applied.
		 */
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, m_uiShadow);
		glEnable(GL_TEXTURE_2D);
		
		DrawMesh(pNode, true);
		
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
	}
	else
	{
		DrawMesh(pNode);
	}
	
	/*
	 Draw the shadow caster
	 
	 */
	
	glPushMatrix();
	glEnable(GL_LIGHTING);
	
	pNode = &m_Scene->pNode[eShadowCaster];
	
	m_Scene->GetWorldMatrix(mWorld, *pNode);
	
	MatrixMultiply(fTransform, mWorld, m_mObjectRotation);
	MatrixMultiply(mModelView, fTransform, m_mView);
	
	glLoadMatrixf(mModelView.f);
	
	if (pNode->nIdxMaterial == -1)
	{
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, 0);
	}
	else
	{
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, m_puiTextures[pNode->nIdxMaterial]);
	}
	
	DrawMesh(pNode);
	
	glDisable(GL_LIGHTING);
	glPopMatrix();
	
	/*
	 Draw the shadows
	 */
	VECTOR3 fCentre;
	
	switch(m_ui32Mode)
	{
		case BASEBLOBMODE:
			fCentre.x = f2vt(0.0f);
			fCentre.y = f2vt(0.0f);
			fCentre.z = f2vt(0.0f);
			
			/* Set the modelview without the kettle rotation */
			MatrixMultiply(mModelView, mWorld, m_mView);
			glLoadMatrixf(mModelView.f);
			
			DrawBaseBlob(fCentre);
			AppDisplayText->DisplayDefaultTitle("Shadow Techniques", "Base Blob", eDisplayTextLogoIMG);
			break;
		case ADVANCEDBLOBMODE:
			/* Set the modelview without the kettle rotation */
			MatrixMultiply(mModelView, mWorld, m_mView);
			glLoadMatrixf(mModelView.f);
			
			DrawAdvancedBlobShadow();
			AppDisplayText->DisplayDefaultTitle("Shadow Techniques", "Dynamic Blob", eDisplayTextLogoIMG);
			break;
		case PROJGEOMMODE:
			glLoadMatrixf(m_mView.f);
			DrawProjectedShadow(pNode);
			AppDisplayText->DisplayDefaultTitle("Shadow Techniques", "Projected geometry", eDisplayTextLogoIMG);
			break;
		case R2TEXMODE:
			// This shadow is drawn when the ground is drawn.
			AppDisplayText->DisplayDefaultTitle("Shadow Techniques", "Projected render (Using copy to texture)", eDisplayTextLogoIMG);
			
			DrawShadowTexture();
			break;
	};
	
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
		
	AppDisplayText->Flush();	
	
	return true;
}

/*!****************************************************************************
 @Function		DrawMesh
 @Input			mesh		The mesh to draw
 @Description	Draws a SPODMesh after the model view matrix has been set and
 the meterial prepared.
 ******************************************************************************/
void DrawMesh(SPODNode* pNode, bool bProjectTexture)
{
	unsigned int ui32MeshID = pNode->nIdx;

	// Get Mesh referenced by the pNode
	SPODMesh& Mesh = m_Scene->pMesh[ui32MeshID];
	
	// Bind the vertex buffers
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[ui32MeshID]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[ui32MeshID]);

	glVertexPointer(3, VERTTYPEENUM, Mesh.sVertex.nStride, Mesh.sVertex.pData);
	glNormalPointer(VERTTYPEENUM   , Mesh.sNormals.nStride, Mesh.sNormals.pData);
	
	glClientActiveTexture(GL_TEXTURE0);
	glTexCoordPointer(2, VERTTYPEENUM, Mesh.psUVW[0].nStride, Mesh.psUVW[0].pData);
	
	if(bProjectTexture)
	{
		glMatrixMode(GL_TEXTURE);
		glPushMatrix();
		glLoadIdentity();
		
		glClientActiveTexture(GL_TEXTURE1);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glTexCoordPointer(3, VERTTYPEENUM, Mesh.sVertex.nStride , Mesh.sVertex.pData);
		
		glLoadIdentity();
		
		glTranslatef(f2vt(0.5f), f2vt(0.5f), f2vt(0.0f));
		glScalef(f2vt(0.003f), f2vt(0.003f), f2vt(1.0f));
		
		glMultMatrixf(m_mLightView.f);
	}
	
	// Indexed Triangle list
	glDrawElements(GL_TRIANGLES, Mesh.nNumFaces*3, GL_UNSIGNED_SHORT, 0);
	
	if(bProjectTexture)
	{
		glClientActiveTexture(GL_TEXTURE1);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glPopMatrix();
		
		glMatrixMode(GL_MODELVIEW);
	}

	// unbind the vertex buffers as we don't need them bound anymore
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

/*!****************************************************************************
 @Function		DrawProjectedShadow
 @Return		void
 @Description	Squish the mesh to the ground plane and draw it.
 ******************************************************************************/
void DrawProjectedShadow(SPODNode* pNode)
{
	glPushMatrix();
	
	// Multiply the view matrix by the model (mWorld) matrix to get the model-view matrix
	MATRIX m_mfloorShadow;
	VECTOR4 vCurLightPos;
	vCurLightPos.x = m_vLightPos.x;
	vCurLightPos.y = m_vLightPos.y;
	vCurLightPos.z = m_vLightPos.z;
	vCurLightPos.w = f2vt(0.0f);
	
	shadowMatrix(m_mfloorShadow, m_fPlane, vCurLightPos);
	glMultMatrixf(m_mfloorShadow.f);
	
	// Enable Polygon offset to avoid ZFighting between floor and shadow
	glEnable(GL_POLYGON_OFFSET_FILL);
	
	// Disable Blending since alpha blend does not work with projection
	glDisable (GL_BLEND);
	
	// Disable Texture
	glDisable(GL_TEXTURE_2D);
	
	// Set the Shadow Color and Alpha
	glColor4f(f2vt(0.0f), f2vt(0.0f), f2vt(0.0f), f2vt(0.5f));
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	
	/* Set the transformation of the kettle */
	MATRIX fTransform, mWorld;
	m_Scene->GetWorldMatrix(mWorld, *pNode);
	MatrixMultiply(fTransform, mWorld, m_mObjectRotation);
	glMultMatrixf(fTransform.f);
	
	// Render the objects which will be slammed into the floor plane
	DrawMesh(pNode);
	
	// Disable Polygon offset to avoid ZFighting between floor and shadow
	glDisable(GL_POLYGON_OFFSET_FILL);
	glEnable(GL_TEXTURE_2D);
	glEnable (GL_BLEND);
	
	glPopMatrix();
}

/*!****************************************************************************
 @Function		shadowMatrix
 @Return		void
 @Description	Create a matrix to squish the mesh.
 ******************************************************************************/
void shadowMatrix(MATRIX &shadowMat, const VECTOR4 &vPlane, const VECTOR4 &vlightPos)
{
	VERTTYPE fDot;
	
	/* Find dot product between light position vector and ground plane normal. */
	fDot =
	VERTTYPEMUL(vPlane.x, vlightPos.x) +
	VERTTYPEMUL(vPlane.y, vlightPos.y) +
	VERTTYPEMUL(vPlane.z, vlightPos.z) +
	VERTTYPEMUL(vPlane.w, vlightPos.w);
	
	shadowMat.f[ 0] = fDot - VERTTYPEMUL(vlightPos.x, vPlane.x);
	shadowMat.f[ 4] = 0   - VERTTYPEMUL(vlightPos.x, vPlane.y);
	shadowMat.f[ 8] = 0   - VERTTYPEMUL(vlightPos.x, vPlane.z);
	shadowMat.f[12] = 0   - VERTTYPEMUL(vlightPos.x, vPlane.w);
	
	shadowMat.f[ 1] = 0   - VERTTYPEMUL(vlightPos.y, vPlane.x);
	shadowMat.f[ 5] = fDot - VERTTYPEMUL(vlightPos.y, vPlane.y);
	shadowMat.f[ 9] = 0   - VERTTYPEMUL(vlightPos.y, vPlane.z);
	shadowMat.f[13] = 0   - VERTTYPEMUL(vlightPos.y, vPlane.w);
	
	shadowMat.f[ 2] = 0   - VERTTYPEMUL(vlightPos.z, vPlane.x);
	shadowMat.f[ 6] = 0   - VERTTYPEMUL(vlightPos.z, vPlane.y);
	shadowMat.f[10] = fDot - VERTTYPEMUL(vlightPos.z, vPlane.z);
	shadowMat.f[14] = 0   - VERTTYPEMUL(vlightPos.z, vPlane.w);
	
	shadowMat.f[ 3] = 0   - VERTTYPEMUL(vlightPos.w, vPlane.x);
	shadowMat.f[ 7] = 0   - VERTTYPEMUL(vlightPos.w, vPlane.y);
	shadowMat.f[11] = 0   - VERTTYPEMUL(vlightPos.w, vPlane.z);
	shadowMat.f[15] = fDot - VERTTYPEMUL(vlightPos.w, vPlane.w);
}

/*!****************************************************************************
 @Function		DrawBaseBlob
 @Return		void
 @Description	Draw a base blob around the input coordinate
 ******************************************************************************/
void DrawBaseBlob(VECTOR3 fCentre)
{
	glDisableClientState(GL_NORMAL_ARRAY);
	
	VERTTYPE	Vertices[] = {
		fCentre.x + f2vt(CHARWIDTH)	, fCentre.y + f2vt(FLOORHEIGHT), fCentre.z + f2vt(-CHARWIDTH),
		fCentre.x + f2vt(-CHARWIDTH), fCentre.y + f2vt(FLOORHEIGHT), fCentre.z + f2vt(-CHARWIDTH),
		fCentre.x + f2vt(CHARWIDTH)	, fCentre.y + f2vt(FLOORHEIGHT), fCentre.z + f2vt(CHARWIDTH) ,
		fCentre.x + f2vt(-CHARWIDTH), fCentre.y + f2vt(FLOORHEIGHT), fCentre.z + f2vt(CHARWIDTH)
	};
	
	static VERTTYPE	UVs[] = {
		f2vt(0.0f), f2vt(0.0f),
		f2vt(1.0f), f2vt(0.0f),
		f2vt(0.0f), f2vt(1.0f),
		f2vt(1.0f), f2vt(1.0f)
	};
	
	// Enable Polygon offset to avoid ZFighting between floor and shadow
	glEnable(GL_POLYGON_OFFSET_FILL);
	
	// Enable Blending for Transparent Blob
	glEnable (GL_BLEND);
	glBlendFunc(GL_DST_COLOR, GL_ZERO);
	
	// Bind Blob Texture
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D,m_uiBlobMap);
	
	// Set Base Blend color to influence how transparent the shadow is
//	glColor4f(f2vt(0.0f), f2vt(0.0f), f2vt(0.0f), f2vt(0.7f));
	
	// Draw Blob - in this case the object is "static" so blob position is "static" as well
	// In a Game the Blob position would be calculated from the Character Position.
	
	VERTTYPE *pVertices = ( (VERTTYPE*)&Vertices );
	VERTTYPE *pUV       = ( (VERTTYPE*)&UVs );
	
	/* Enable Client States and Setup Data Pointers */
	glVertexPointer(3,VERTTYPEENUM,0,pVertices);
	
	glClientActiveTexture(GL_TEXTURE0);
	glTexCoordPointer(2,VERTTYPEENUM,0,pUV);
	
	/* Draw Geometry */
	glDrawArrays(GL_TRIANGLE_STRIP,0,4);
	
	glColor4f(f2vt(1.0f), f2vt(1.0f), f2vt(1.0f), f2vt(1.0f));
	
	// Disable blending
	glDisable (GL_BLEND);
	
	// Disable Polygon offset to avoid ZFighting between floor and shadow
	glDisable(GL_POLYGON_OFFSET_FILL);
	
	glEnableClientState(GL_NORMAL_ARRAY);
}

/*!****************************************************************************
 @Function		DrawAdvancedBlobShadow
 @Return		void
 @Description	Find the intersection point of the ray to the ground plane
 and place a blob there.
 ******************************************************************************/
void DrawAdvancedBlobShadow()
{
	VECTOR3 fRay, fNorm, fInter;
	
	fRay.x = m_fObjectCentre.x - m_vLightPos.x;
	fRay.y = m_fObjectCentre.y - m_vLightPos.y;
	fRay.z = m_fObjectCentre.z - m_vLightPos.z;
	
	fNorm.x = m_fPlane.x;
	fNorm.y = m_fPlane.y;
	fNorm.z = m_fPlane.z;
	
	MatrixVec3Normalize(fRay, fRay);
	
	VERTTYPE fAlpha = m_fPlane.w - MatrixVec3DotProduct(fNorm, m_vLightPos);
	VERTTYPE fK =  MatrixVec3DotProduct(fNorm,fRay);
	
	if(fK != 0.0f)
	{
		fAlpha = VERTTYPEDIV(fAlpha, fK);
	}
	
	if(fK == 0.0f)
	{
		fInter.x = f2vt(0.0f);
		fInter.y = f2vt(0.0f);
		fInter.z = f2vt(0.0f);
	}
	else
	{
		fInter.x = m_vLightPos.x + VERTTYPEMUL(fAlpha, fRay.x);
		fInter.y = 0;
		fInter.z = m_vLightPos.z + VERTTYPEMUL(fAlpha, fRay.z);
	}
	
	DrawBaseBlob(fInter);
}
