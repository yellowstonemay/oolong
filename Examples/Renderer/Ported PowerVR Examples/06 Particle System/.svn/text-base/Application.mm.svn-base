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
CTexture * Textures;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

int frames;
float frameRate;

// Contains the partice utility class
#include "Particle.h"

#define WIDTH 320
#define HEIGHT 480

/******************************************************************************
 Defines
 ******************************************************************************/

const unsigned int g_ui32MaxParticles = 1000;					// Maximum number of m_Particles
const VERTTYPE g_fFactor = f2vt(0.25f);							// Brightness of the reflected m_Particles
const Vec3 g_fUp(f2vt(0.0f), f2vt(1.0f), f2vt(0.0f));		// Up direction. Used for creating the camera

MATRIX mProjection, m_mView;

/******************************************************************************
 Structure definitions
 ******************************************************************************/

struct SVtx
{
	VERTTYPE	x, y, z;						// Position
	unsigned char 	u, v;						// TexCoord
};

struct SVtxPointSprite
{
	VERTTYPE	x, y, z, fSize;
};

struct SColors
{
	unsigned char	r,g,b,a;						// Color
};

// Texture names
	GLuint 			m_ui32TexName;
	GLuint 			m_ui32FloorTexName;

// Particle instance pointers
	CParticle m_Particles[g_ui32MaxParticles];

// Vectors for calculating the view matrix and saving the camera position
Vec3 m_fFrom, m_fTo;

// Particle geometry buffers
SVtx	m_sParticleVTXBuf[g_ui32MaxParticles*4]; // 4 Vertices per Particle - 2 triangles
SColors m_sNormalColour[g_ui32MaxParticles*4];
SColors m_sReflectColour[g_ui32MaxParticles*4];
unsigned short m_ui16ParticleINDXBuf[g_ui32MaxParticles * 6]; // 3 indices per triangle

SVtxPointSprite	m_sParticleVTXPSBuf[g_ui32MaxParticles]; // When using point sprites
GLuint m_i32VertVboID;
GLuint m_i32ColAVboID;
GLuint m_i32ColBVboID;
GLuint m_i32QuadVboID;

VERTTYPE m_fFloorQuadVerts[4*4];
VERTTYPE m_fFloorQuadUVs[2*4];
SVtx	 m_sQuadVTXBuf[4];

// Dynamic state
int		m_i32NumParticles;
float	m_fRot, m_fRot2;
float	m_fPointAttenuationCoef;



float RandPositiveFloat();
float RandFloat();
void  RenderFloor();
void  SpawnParticle(CParticle *pParticle);
void  RenderParticle(int i32ParticleNo, bool bReflect);
VERTTYPE Clamp(VERTTYPE input);

bool CShell::InitApplication()
{
	//	LOGFUNC("InitApplication()");
	
	AppDisplayText = new CDisplayText;  
	Textures = new CTexture;
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
				printf("Display text textures loaded\n");
	/*
	 Initializes variables.
	 */
        m_i32NumParticles = 0;
	m_fRot = 0;
	m_fRot2 = 0;
	m_fFrom = Vec3(f2vt(0.0f), f2vt(45.0f), f2vt(120.0f));
	m_fTo	= Vec3(f2vt(0.0f), f2vt(20.0f), f2vt(-1.0f));
		
	Textures = (CTexture*)malloc(sizeof(CTexture));
	memset(Textures, 0, sizeof(CTexture));
	
	char *buffer = new char[2048];
	GetResourcePathASCII(buffer, 2048);
	
/*
// PVR texture files
const char c_szLightTexFile[] = "LightTex.pvr";
const char c_szFloorTexFile[] = "FloorTex8.pvr";
*/
	/*
	 Load textures.
	 */
	char *filename = new char[2048];
	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/LightTex.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32TexName))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	memset(filename, 0, 2048 * sizeof(char));
	sprintf(filename, "%s/FloorTex8.pvr", buffer);
	if(!Textures->LoadTextureFromPVR(filename, &m_ui32FloorTexName))
		return false;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	/*
	 Creates the projection matrix.
	 */
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	MatrixPerspectiveFovRH(mProjection, f2vt(45.0f*(PIf/180.0f)), f2vt((float)WIDTH/(float)HEIGHT), f2vt(10.0f), f2vt(1200.0f), true);
	glMultMatrixf(mProjection.f);
	
	/*
	 Calculates the attenuation coefficient for the points drawn.
	 */
	double H = HEIGHT;
	double h = 2.0/mProjection.f[5];
	double D0 = sqrt(2.0)*H/h;
	double k = 1.0/(1.0 + 2.0 * (1/mProjection.f[5])*(1/mProjection.f[5]));
	m_fPointAttenuationCoef = (float)(1.0/(D0*D0)*k);
	
	/*
	 Creates the model view matrix.
	 */
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	MatrixLookAtRH(m_mView, m_fFrom, m_fTo, g_fUp);
	glLoadMatrixf(m_mView.f);
	
	/*
	 Pre-Set TexCoords since they never change.
	 Pre-Set the Index Buffer.
	 */

	for(unsigned int i = 0; i < g_ui32MaxParticles; ++i)
	{
		m_sParticleVTXBuf[i*4+0].u = 0;
		m_sParticleVTXBuf[i*4+0].v = 0;
		
		m_sParticleVTXBuf[i*4+1].u = 1;
		m_sParticleVTXBuf[i*4+1].v = 0;
		
		m_sParticleVTXBuf[i*4+2].u = 0;
		m_sParticleVTXBuf[i*4+2].v = 1;
		
		m_sParticleVTXBuf[i*4+3].u = 1;
		m_sParticleVTXBuf[i*4+3].v = 1;
		
		m_ui16ParticleINDXBuf[i*6+0] = (i*4) + 0;
		m_ui16ParticleINDXBuf[i*6+1] = (i*4) + 1;
		m_ui16ParticleINDXBuf[i*6+2] = (i*4) + 2;
		m_ui16ParticleINDXBuf[i*6+3] = (i*4) + 2;
		m_ui16ParticleINDXBuf[i*6+4] = (i*4) + 1;
		m_ui16ParticleINDXBuf[i*6+5] = (i*4) + 3;
	}
	
	
	//	Create vertex buffers.
	glGenBuffers(1, &m_i32VertVboID);
	glGenBuffers(1, &m_i32ColAVboID);
	glGenBuffers(1, &m_i32ColBVboID);
	glGenBuffers(1, &m_i32QuadVboID);
	
	//	Preset the floor uvs and vertices as they never change.
	Vec3 pos(0, 0, 0);
	
	float szby2 = 100;
	
	m_sQuadVTXBuf[0].x = m_fFloorQuadVerts[0]  = pos.x - f2vt(szby2);
	m_sQuadVTXBuf[0].y = m_fFloorQuadVerts[1]  = pos.y;
	m_sQuadVTXBuf[0].z = m_fFloorQuadVerts[2]  = pos.z - f2vt(szby2);
	
	m_sQuadVTXBuf[1].x = m_fFloorQuadVerts[3]  = pos.x + f2vt(szby2);
	m_sQuadVTXBuf[1].y = m_fFloorQuadVerts[4]  = pos.y;
	m_sQuadVTXBuf[1].z = m_fFloorQuadVerts[5]  = pos.z - f2vt(szby2);
	
	m_sQuadVTXBuf[2].x = m_fFloorQuadVerts[6]  = pos.x - f2vt(szby2);
	m_sQuadVTXBuf[2].y = m_fFloorQuadVerts[7]  = pos.y;
	m_sQuadVTXBuf[2].z = m_fFloorQuadVerts[8]  = pos.z + f2vt(szby2);
	
	m_sQuadVTXBuf[3].x = m_fFloorQuadVerts[9]  = pos.x + f2vt(szby2);
	m_sQuadVTXBuf[3].y = m_fFloorQuadVerts[10] = pos.y;
	m_sQuadVTXBuf[3].z = m_fFloorQuadVerts[11] = pos.z + f2vt(szby2);
	
	m_fFloorQuadUVs[0] = f2vt(0);
	m_fFloorQuadUVs[1] = f2vt(0);
	m_sQuadVTXBuf[0].u = 0;
	m_sQuadVTXBuf[0].v = 0;

	m_fFloorQuadUVs[2] = f2vt(1);
	m_fFloorQuadUVs[3] = f2vt(0);
	m_sQuadVTXBuf[1].u = 255;
	m_sQuadVTXBuf[1].v = 0;
	
	m_fFloorQuadUVs[4] = f2vt(0);
	m_fFloorQuadUVs[5] = f2vt(1);
	m_sQuadVTXBuf[2].u = 0;
	m_sQuadVTXBuf[2].v = 255;

	m_fFloorQuadUVs[6] = f2vt(1);
	m_fFloorQuadUVs[7] = f2vt(1);
	m_sQuadVTXBuf[3].u = 255;
	m_sQuadVTXBuf[3].v = 255;
	
	glBindBuffer(GL_ARRAY_BUFFER, m_i32QuadVboID);
	glBufferData(GL_ARRAY_BUFFER, sizeof(SVtx) * 4, m_sQuadVTXBuf, GL_STATIC_DRAW);
	
	delete [] filename;
	delete [] buffer;
	
	return true;
}

bool CShell::QuitApplication()
{
	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;

	// Release textures
	Textures->ReleaseTexture(m_ui32TexName);
	Textures->ReleaseTexture(m_ui32FloorTexName);
	
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
	
	AppDisplayText->DisplayText(0, 10, 0.4f, RGBA(255,255,255,255), "fps: %3.2f", frameRate);
	
	return true;
}


bool CShell::RenderScene()
{
	int				i;
	MATRIX mRotY;
	
	// Clear colour and depth buffers
	glClearColor(f2vt(0.0f), f2vt(0.0f), f2vt(0.0f), f2vt(1.0f));
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// Enables depth testing
	glEnable(GL_DEPTH_TEST);
	
	//	Modify per-frame variables controlling the particle mouvements.
	float fSpeedCtrl = (float) (sinf(m_fRot*0.01f)+1.0f)/2.0f;
	float fStopNo = 0.8f;
	float fStep = 0.1f;
	
	if(fSpeedCtrl > fStopNo)
		fStep = 0.0f;

	// Generate particles as needed.
	if((m_i32NumParticles < (int) g_ui32MaxParticles) && (fSpeedCtrl <= fStopNo))
	{
		int num_to_gen = (int) (RandPositiveFloat()*(g_ui32MaxParticles/100.0));
		
		if (num_to_gen==0)
			num_to_gen=1;
		
		for(i = 0; (i < num_to_gen) && (m_i32NumParticles < (int) g_ui32MaxParticles); ++i)
			SpawnParticle(&m_Particles[m_i32NumParticles++]);
	}
	
	// Build rotation matrix around axis Y.
	MatrixRotationY(mRotY, f2vt((m_fRot2 * PIf)/180.0f));
//	mRotY = MatrixRotationY(f2vt((m_fRot2 * PIf)/180.0f));
	
	for(i = 0; i < m_i32NumParticles; ++i)
	{
		// Transform particle with rotation matrix
		m_sParticleVTXPSBuf[i].x =	VERTTYPEMUL(mRotY.f[ 0], m_Particles[i].m_fPosition.x) +
								VERTTYPEMUL(mRotY.f[ 4], m_Particles[i].m_fPosition.y) +
								VERTTYPEMUL(mRotY.f[ 8], m_Particles[i].m_fPosition.z) +
											mRotY.f[12];
		m_sParticleVTXPSBuf[i].y =	VERTTYPEMUL(mRotY.f[ 1], m_Particles[i].m_fPosition.x) +
								VERTTYPEMUL(mRotY.f[ 5], m_Particles[i].m_fPosition.y) +
								VERTTYPEMUL(mRotY.f[ 9], m_Particles[i].m_fPosition.z) +
											mRotY.f[13];
		m_sParticleVTXPSBuf[i].z =	VERTTYPEMUL(mRotY.f[ 2], m_Particles[i].m_fPosition.x) +
								VERTTYPEMUL(mRotY.f[ 6], m_Particles[i].m_fPosition.y) +
								VERTTYPEMUL(mRotY.f[10], m_Particles[i].m_fPosition.z) +
											mRotY.f[14];
			
		m_sParticleVTXPSBuf[i].fSize = m_Particles[i].m_fSize;
			
		m_sNormalColour[i].r  = vt2b(m_Particles[i].m_fColour.x);
		m_sNormalColour[i].g  = vt2b(m_Particles[i].m_fColour.y);
		m_sNormalColour[i].b  = vt2b(m_Particles[i].m_fColour.z);
		m_sNormalColour[i].a  = (unsigned char)255;
			
		m_sReflectColour[i].r  = vt2b(VERTTYPEMUL(m_Particles[i].m_fColour.x, g_fFactor));
		m_sReflectColour[i].g  = vt2b(VERTTYPEMUL(m_Particles[i].m_fColour.y, g_fFactor));
		m_sReflectColour[i].b  = vt2b(VERTTYPEMUL(m_Particles[i].m_fColour.z, g_fFactor));
		m_sReflectColour[i].a  = (unsigned char)255;
	}
			
	glBindBuffer(GL_ARRAY_BUFFER, m_i32VertVboID);
	glBufferData(GL_ARRAY_BUFFER, sizeof(SVtxPointSprite)*m_i32NumParticles, m_sParticleVTXPSBuf,GL_DYNAMIC_DRAW);
			
	glBindBuffer(GL_ARRAY_BUFFER, m_i32ColAVboID);
	glBufferData(GL_ARRAY_BUFFER, sizeof(SColors)*m_i32NumParticles, m_sNormalColour,GL_DYNAMIC_DRAW);
			
	glBindBuffer(GL_ARRAY_BUFFER, m_i32ColBVboID);
	glBufferData(GL_ARRAY_BUFFER, sizeof(SColors)*m_i32NumParticles, m_sReflectColour,GL_DYNAMIC_DRAW);
	
	// clean up render states
	glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
	glEnable(GL_LIGHTING);
	
	//	Draw floor.
	
	// Save modelview matrix
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glRotatef(f2vt(-m_fRot), f2vt(0.0f), f2vt(1.0f), f2vt(0.0f));
	
	// setup render states
	glDisable(GL_LIGHTING);
	glEnable(GL_TEXTURE_2D);
	glDisable(GL_CULL_FACE);
	glEnable(GL_BLEND);
	
	// Set texture and texture environment
	glBindTexture(GL_TEXTURE_2D, m_ui32FloorTexName);
	glBlendFunc(GL_ONE, GL_ONE);
	
	// Render floor
	RenderFloor();
	
	// clean up render states
	glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
	glEnable(GL_LIGHTING);
	
	glPopMatrix();
	
	//	Render particles reflections.
	
	// set up render states
	glDisable(GL_LIGHTING);
	glEnable(GL_TEXTURE_2D);

	glDepthFunc(GL_ALWAYS);
	glDisable(GL_CULL_FACE);

	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE);

	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glBindTexture(GL_TEXTURE_2D, m_ui32TexName);
	
	// Set model view matrix
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	
	glScalef(f2vt(1.0f), f2vt(-1.0f), f2vt(1.0f));
	glTranslatef(f2vt(0.0f), f2vt(0.01f), f2vt(0.0f));

	glEnable(GL_POINT_SPRITE_OES);

	if(((int)(m_i32NumParticles * 0.5f)) > 0)
       RenderParticle(((int)(m_i32NumParticles*0.5f)),true);

	glPopMatrix();
	
	//	Render particles.
	
	// Sets the model view matrix
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	
	if(m_i32NumParticles > 0)
        RenderParticle(m_i32NumParticles,false);
	
	glPopMatrix();

	glDisable(GL_POINT_SPRITE_OES);
	
	Vec3 Force = Vec3(f2vt(0.0f), f2vt(0.0f), f2vt(0.0f));
	Force.x = f2vt(1000.0f*(float)sinf(m_fRot*0.01f));
	
	for(i = 0; i < m_i32NumParticles; ++i)
	{
		/*
		 Move the particle.
		 If the particle exceeds its lifetime, create a new one in its place.
		 */
		if(m_Particles[i].Step(f2vt(fStep), Force))
			SpawnParticle(&m_Particles[i]);
	}
	
	// clean up render states
	glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
	glEnable(GL_LIGHTING);
	
	// Increase rotation angles
	m_fRot += 1;
	m_fRot2 = m_fRot + 36;
	
	// Unbinds the vertex buffer if we are using OpenGL ES 1.1
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	// show text on the display
	AppDisplayText->DisplayDefaultTitle("Particles", "(using point sprites with buffer objects)", eDisplayTextLogoIMG);


	AppDisplayText->Flush();	
	
	return true;
}

/*!****************************************************************************
 @Function		rand_float
 @Return		float		random float from -1 to 1
 @Description	returns a random float in range -1 to 1.
 ******************************************************************************/
float RandFloat()
{
	return (rand()/(float)RAND_MAX) * 2.0f - 1.0f;
}

/*!****************************************************************************
 @Function		rand_positive_float
 @Return		float		random float from 0 to 1
 @Description	returns a random float in range 0 to 1.
 ******************************************************************************/
float RandPositiveFloat()
{
	return rand()/(float)RAND_MAX;
}

/*!****************************************************************************
 @Function		spawn_particle
 @Output		the_particle	particle to initialize
 @Description	initializes the specified particle with randomly chosen parameters.
 ******************************************************************************/
void SpawnParticle(CParticle *pParticle)
{
	Vec3 fParticleSource(f2vt(0), f2vt(0), f2vt(0));
	Vec3 fParticleSourceVariability(f2vt(1), f2vt(0), f2vt(1));
	Vec3 fParticleVelocity(f2vt(0), f2vt(30), f2vt(0));
	Vec3 fParticleVelocityVariability(f2vt(4), f2vt(15), f2vt(4));
	VERTTYPE fParticleLifeTime = f2vt(8);
	VERTTYPE fParticleLifeTimeVariability = f2vt(1.0);
	
	float fParticleMass = 100;
	float fParticleMassVariability = 0;
	float fRndFloat;
	
	// Creates the particle position.
	Vec3 fPos;
	fRndFloat = RandFloat();
	fPos.x = fParticleSource.x + VERTTYPEMUL(f2vt(fRndFloat),fParticleSourceVariability.x);
	fRndFloat = RandFloat();
	fPos.y = fParticleSource.y + VERTTYPEMUL(f2vt(fRndFloat),fParticleSourceVariability.y);
	fRndFloat = RandFloat();
	fPos.z = fParticleSource.z + VERTTYPEMUL(f2vt(fRndFloat),fParticleSourceVariability.z);
	
	// Creates the particle velocity.
	Vec3 fVel;
	fRndFloat = RandFloat();
	fVel.x = fParticleVelocity.x + VERTTYPEMUL(f2vt(fRndFloat),fParticleVelocityVariability.x);
	fRndFloat = RandFloat();
	fVel.y = fParticleVelocity.y + VERTTYPEMUL(f2vt(fRndFloat),fParticleVelocityVariability.y);
	fRndFloat = RandFloat();
	fVel.z = fParticleVelocity.z + VERTTYPEMUL(f2vt(fRndFloat),fParticleVelocityVariability.z);
	
	// Creates the particle lifetime and fMass.
	VERTTYPE fLife = fParticleLifeTime + VERTTYPEMUL(f2vt(RandFloat()), fParticleLifeTimeVariability);
	float fMass = fParticleMass + RandFloat() * fParticleMassVariability;
	
	// Creates the particle from these characteristics.
	*pParticle = CParticle(fPos,fVel,fMass,fLife);
	
	// Creates the particle colors.
	Vec3 fParticleInitialColour(f2vt(0.6f*255.0f), f2vt(0.5f*255.0f), f2vt(0.5f*255.0f));
	Vec3 fParticleInitialColourVariability(f2vt(0.2f*255.0f), f2vt(0.2f*255.0f), f2vt(0.2f*255.0f));
	
	Vec3 fParticleHalfwayColour(f2vt(1.0f*255.0f), f2vt(0.0f), f2vt(0.0f));
	Vec3 fParticleHalfwayColourVariability(f2vt(0.8f*255.0f), f2vt(0.0f), f2vt(0.3f*255.0f));
	
	Vec3 fParticleEndColour(f2vt(0.0f), f2vt(0.0f), f2vt(0.0f));
	Vec3 fParticleEndColourVariability(f2vt(0.0f), f2vt(0.0f), f2vt(0.0f));
	
	VERTTYPE fRndValue = f2vt(RandFloat());
	pParticle->m_fColour.x = pParticle->m_fInitialColour.x = Clamp(fParticleInitialColour.x + VERTTYPEMUL(fParticleInitialColourVariability.x,fRndValue));
	pParticle->m_fColour.y = pParticle->m_fInitialColour.y = Clamp(fParticleInitialColour.y + VERTTYPEMUL(fParticleInitialColourVariability.y,fRndValue));
	pParticle->m_fColour.z = pParticle->m_fInitialColour.z = Clamp(fParticleInitialColour.z + VERTTYPEMUL(fParticleInitialColourVariability.z,fRndValue));

	fRndFloat = RandFloat();
	pParticle->m_fHalfwayColour.x = Clamp(fParticleHalfwayColour.x + VERTTYPEMUL(f2vt(fRndFloat), fParticleHalfwayColourVariability.x));
	fRndFloat = RandFloat();
	pParticle->m_fHalfwayColour.y = Clamp(fParticleHalfwayColour.y + VERTTYPEMUL(f2vt(fRndFloat), fParticleHalfwayColourVariability.y));
	fRndFloat = RandFloat();
	pParticle->m_fHalfwayColour.z = Clamp(fParticleHalfwayColour.z + VERTTYPEMUL(f2vt(fRndFloat), fParticleHalfwayColourVariability.z));
	
	fRndFloat = RandFloat();
	pParticle->m_fEndColor.x = Clamp(fParticleEndColour.x + VERTTYPEMUL(f2vt(fRndFloat), fParticleEndColourVariability.x));
	fRndFloat = RandFloat();
	pParticle->m_fEndColor.y = Clamp(fParticleEndColour.y + VERTTYPEMUL(f2vt(fRndFloat), fParticleEndColourVariability.y));
	fRndFloat = RandFloat();
	pParticle->m_fEndColor.z = Clamp(fParticleEndColour.z + VERTTYPEMUL(f2vt(fRndFloat), fParticleEndColourVariability.z));
	
	// Creates the particle size using a perturbation.
	VERTTYPE fParticleSize = f2vt(2.0f);
	VERTTYPE fParticleSizeVariation = f2vt(1.5f);
	fRndFloat = RandFloat();
	pParticle->m_fSize = fParticleSize + VERTTYPEMUL(f2vt(fRndFloat), fParticleSizeVariation);
}

/*!****************************************************************************
 @Function		render_particle
 @Input			NmbrOfParticles		number of particles to initialize
 @Input			bReflect			should we use the reflection color ?
 @Description	Renders the specified set of particles, optionally using the
 reflection color.
 ******************************************************************************/
void RenderParticle(int i32ParticleNo, bool bReflect)
{
	//	If point sprites are availables, use them to draw the particles.
	glBindBuffer(GL_ARRAY_BUFFER, m_i32VertVboID);
		
		glEnableClientState(GL_VERTEX_ARRAY);
		glVertexPointer(3,VERTTYPEENUM,sizeof(SVtxPointSprite),0);
		
	glTexEnvf( GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE );
		
		glEnableClientState(GL_POINT_SIZE_ARRAY_OES);
		glPointSizePointerOES(VERTTYPEENUM,sizeof(SVtxPointSprite),(GLvoid*) (sizeof(VERTTYPE)*3));
		
#ifndef PVRT_FIXED_POINT_ENABLE
	float fCoefs[4] = { 0, 0, m_fPointAttenuationCoef, 0 };
#else
	// Note: m_fPointAttenuationCoef will be too small to represent as a fixed point number,
		// So use an approximation to the attenuation (fixed attenuation of 0.01) instead.
	VERTTYPE fCoefs[4] = { f2vt(0.01f), f2vt(0.0f), f2vt(0.0f), f2vt(0.0f) };
#endif

	glPointParameterfv(GL_POINT_DISTANCE_ATTENUATION, fCoefs);

	glEnableClientState(GL_COLOR_ARRAY);

	glBindBuffer(GL_ARRAY_BUFFER, bReflect ? m_i32ColBVboID : m_i32ColAVboID);

	glColorPointer(4,GL_UNSIGNED_BYTE,0,0);
		
	glDrawArrays(GL_POINTS, 0, i32ParticleNo);
		
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_POINT_SIZE_ARRAY_OES);
	glDisableClientState(GL_COLOR_ARRAY);
}

/*!****************************************************************************
 @Function		clamp
 @Input			X			number to clamp
 @Return		VERTTYPE	clamped number
 @Description	Clamps the argument to 0-255.
 ******************************************************************************/
VERTTYPE Clamp(VERTTYPE X)
{
	if (X<f2vt(0.0f))
		X=f2vt(0.0f);
	else if(X>f2vt(255.0f))
		X=f2vt(255.0f);
	
	return X;
}

/*!****************************************************************************
 @Function		render_floor
 @Description	Renders the floor as a quad.
 ******************************************************************************/
void RenderFloor()
{
	// Draw the floor using regular geometry for the quad.
	glBindBuffer(GL_ARRAY_BUFFER, m_i32QuadVboID);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glVertexPointer(3,VERTTYPEENUM,sizeof(SVtx),0);
	glTexCoordPointer(2,GL_BYTE,sizeof(SVtx),(const GLvoid*) (3*sizeof(VERTTYPE)));
	
	glDrawArrays(GL_TRIANGLE_STRIP,0,4);
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
}


