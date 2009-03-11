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
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
//////////////////////////////////
///Quick Bullet integration
///Todo: move data into class, instead of globals
#include "btBulletDynamicsCommon.h"
#define MAX_PROXIES 8192
static btDiscreteDynamicsWorld* sDynamicsWorld=0;
static btCollisionConfiguration* sCollisionConfig=0;
static btCollisionDispatcher* sCollisionDispatcher=0;
static btSequentialImpulseConstraintSolver* sConstraintSolver;
static btBroadphaseInterface* sBroadphase=0;
btAlignedObjectArray<btCollisionShape*> sCollisionShapes;
btAlignedObjectArray<btRigidBody*> sBoxBodies;
btRigidBody* sFloorPlaneBody=0;
int numBodies = 25;

//////////////////////////////////

//#include "Log.h"
#include "App.h"
#include "Mathematics.h"
#include "GraphicsDevice.h"
#include "UI.h"
#include "Macros.h"
#include "TouchScreen.h"

#include <stdio.h>
#include <sys/time.h>

CDisplayText * AppDisplayText;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

int frames;
float frameRate;

// touch screen values
TouchScreenValues *TouchScreen;
btVector3 Ray;

btVector3 GetRayTo(int x,int y, float nearPlane, float farPlane, btVector3 cameraUp, btVector3 CameraPosition, btVector3 CameraTargetPosition);

bool CShell::InitApplication()
{
//	LOGFUNC("InitApplication()");
	
	AppDisplayText = new CDisplayText;  
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
//		LOG("Display text textures loaded", Logger::LOG_DATA);
				printf("Display text textures loaded\n");


	sCollisionConfig = new btDefaultCollisionConfiguration();
	
	///the maximum size of the collision world. Make sure objects stay within these boundaries
	///Don't make the world AABB size too large, it will harm simulation quality and performance
	btVector3 worldAabbMin(-10000,-10000,-10000);
	btVector3 worldAabbMax(10000,10000,10000);
	sBroadphase = new btAxisSweep3(worldAabbMin,worldAabbMax,MAX_PROXIES);
	sCollisionDispatcher = new btCollisionDispatcher(sCollisionConfig);
	sConstraintSolver = new btSequentialImpulseConstraintSolver;
	sDynamicsWorld = new btDiscreteDynamicsWorld(sCollisionDispatcher,sBroadphase,sConstraintSolver,sCollisionConfig);
	sDynamicsWorld->setGravity(btVector3(0,0,0));
	//btCollisionShape* shape = new btBoxShape(btVector3(1,1,1));
	{
		btTransform groundTransform;
		groundTransform.setIdentity();
		btCollisionShape* groundShape = new btStaticPlaneShape(btVector3(0,1,0),0);
		btScalar mass(0.);	//rigidbody is dynamic if and only if mass is non zero, otherwise static
		bool isDynamic = (mass != 0.f);
		btVector3 localInertia(0,0,0);
		if (isDynamic)
				groundShape->calculateLocalInertia(mass,localInertia);
		//using motionstate is recommended, it provides interpolation capabilities, and only synchronizes 'active' objects
		btDefaultMotionState* myMotionState = new btDefaultMotionState(groundTransform);
		btRigidBody::btRigidBodyConstructionInfo rbInfo(mass,myMotionState,groundShape,localInertia);
		sFloorPlaneBody = new btRigidBody(rbInfo);
		//add the body to the dynamics world
		sDynamicsWorld->addRigidBody(sFloorPlaneBody);
	}
	for (int i=0;i<numBodies;i++)
	{
		btTransform bodyTransform;
		bodyTransform.setIdentity();
		bodyTransform.setOrigin(btVector3(0,10+i*2,0));
		btCollisionShape* boxShape = new btBoxShape(btVector3(1,1,1));
		btScalar mass(1.);//positive mass means dynamic/moving  object
		bool isDynamic = (mass != 0.f);
		btVector3 localInertia(0,0,0);
		if (isDynamic)
				boxShape->calculateLocalInertia(mass,localInertia);
		//using motionstate is recommended, it provides interpolation capabilities, and only synchronizes 'active' objects
		btDefaultMotionState* myMotionState = new btDefaultMotionState(bodyTransform);
		btRigidBody::btRigidBodyConstructionInfo rbInfo(mass,myMotionState,boxShape,localInertia);
		btRigidBody* boxBody=new btRigidBody(rbInfo);
		sBoxBodies.push_back(boxBody);
		//add the body to the dynamics world
		sDynamicsWorld->addRigidBody(boxBody);
	}
	
	return true;
}

bool CShell::QuitApplication()
{
	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;
	
	///cleanup Bullet stuff
	delete sDynamicsWorld;
	sDynamicsWorld =0;
	delete sConstraintSolver;
	sConstraintSolver=0;
	delete sCollisionDispatcher;
	sCollisionDispatcher=0;
	delete sBroadphase;
	sBroadphase=0;
	delete sCollisionConfig;
	sCollisionConfig=0;
	//////////////
	return true;
}

btVector3 m_cameraPosition;
btScalar m_ele(0),m_azi(0);
btVector3 m_cameraUp(0,1,0);
int m_forwardAxis=2;
int m_glutScreenWidth = 320;
int m_glutScreenHeight = 480;
btVector3 m_cameraTargetPosition(0,0,0);
btScalar m_cameraDistance = 20;




void lookAt(GLfloat eyex, GLfloat eyey, GLfloat eyez,
			GLfloat centerx, GLfloat centery, GLfloat centerz,
			GLfloat upx, GLfloat upy, GLfloat upz)
{
	
	GLfloat m[16];
	GLfloat x[3], y[3], z[3];
	btScalar mag;
	
	/* Make rotation matrix */
	
	/* Z vector */
	z[0] = eyex - centerx;
	z[1] = eyey - centery;
	z[2] = eyez - centerz;
	mag = btSqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2]);
	if (mag) {			/* mpichler, 19950515 */
		z[0] /= mag;
		z[1] /= mag;
		z[2] /= mag;
	}
	
	/* Y vector */
	y[0] = upx;
	y[1] = upy;
	y[2] = upz;
	
	/* X vector = Y cross Z */
	x[0] = y[1] * z[2] - y[2] * z[1];
	x[1] = -y[0] * z[2] + y[2] * z[0];
	x[2] = y[0] * z[1] - y[1] * z[0];
	
	/* Recompute Y = Z cross X */
	y[0] = z[1] * x[2] - z[2] * x[1];
	y[1] = -z[0] * x[2] + z[2] * x[0];
	y[2] = z[0] * x[1] - z[1] * x[0];
	
	/* mpichler, 19950515 */
	/* cross product gives area of parallelogram, which is < 1.0 for
	 * non-perpendicular unit-length vectors; so normalize x, y here
	 */
	
	mag = btSqrt( x[0] * x[0] + x[1] * x[1] + x[2] * x[2]);
	if (mag) {
		x[0] /= mag;
		x[1] /= mag;
		x[2] /= mag;
	}
	
	mag = btSqrt( y[0] * y[0] + y[1] * y[1] + y[2] * y[2]);
	if (mag) {
		y[0] /= mag;
		y[1] /= mag;
		y[2] /= mag;
	}
	
#define M(row,col)  m[col*4+row]
	M(0, 0) = x[0];
	M(0, 1) = x[1];
	M(0, 2) = x[2];
	M(0, 3) = 0.0;
	M(1, 0) = y[0];
	M(1, 1) = y[1];
	M(1, 2) = y[2];
	M(1, 3) = 0.0;
	M(2, 0) = z[0];
	M(2, 1) = z[1];
	M(2, 2) = z[2];
	M(2, 3) = 0.0;
	M(3, 0) = 0.0;
	M(3, 1) = 0.0;
	M(3, 2) = 0.0;
	M(3, 3) = 1.0;
#undef M
	glMultMatrixf(m);
	
	/* Translate Eye to Origin */
	glTranslatef(-eyex, -eyey, -eyez);
	
}

btVector3 GetRayTo(int x,int y, float nearPlane, float farPlane, btVector3 cameraUp, btVector3 CameraPosition, btVector3 CameraTargetPosition)
{
	float top = 1.f;
	float bottom = -1.f;
	float tanFov = (top - bottom) * 0.5f / nearPlane;
	float fov = 2.0 * atanf (tanFov);
	
	btVector3	rayFrom = CameraPosition;
	btVector3 rayForward = (CameraTargetPosition - CameraPosition);
	rayForward.normalize();
	//float fPlane = 10000.f;
	rayForward *= farPlane;
	
	btVector3 rightOffset;
	btVector3 vertical = cameraUp;
	
	btVector3 hor;
	
	hor = rayForward.cross(vertical);
	hor.normalize();
	vertical = hor.cross(rayForward);
	vertical.normalize();
	
	float tanfov = tanf(0.5f*fov);
	
	float aspect = (float)480 / (float)320;
	
	hor *= 2.f * farPlane * tanfov;
	vertical *= 2.f * farPlane * tanfov;
	
	if (aspect<1)
	{
		hor/=aspect;
	} else
	{
		vertical*=aspect;
	}
	
	btVector3 rayToCenter = rayFrom + rayForward;
	btVector3 dHor = hor * 1.f/float(320);
	btVector3 dVert = vertical * 1.f/float(480);
	
	btVector3 rayTo = rayToCenter - 0.5f * hor + 0.5f * vertical;
	rayTo += x * dHor;
	rayTo -= y * dVert;
	return rayTo;
}


bool CShell::UpdateScene()
{
    glEnable(GL_DEPTH_TEST);
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	//    glDisable(GL_CULL_FACE);
	
	//	UpdatePolarCamera();
	/*
	 //Set the OpenGL projection matrix
	 glMatrixMode(GL_PROJECTION);
	 glLoadIdentity();
	 
	 MATRIX	MyPerspMatrix;
	 MatrixPerspectiveFovRH(MyPerspMatrix, f2vt(70), f2vt(((float) 320 / (float) 480)), f2vt(1.0f), f2vt(10000.0f), 0);
	 myglMultMatrix(MyPerspMatrix.f);
	 
	 //	glOrthof(-40 / 2, 40 / 2, -60 / 2, 60 / 2, -1, 1);
	 
	 static CFTimeInterval	startTime = 0;
	 CFTimeInterval			time;
	 
	 //Calculate our local time
	 time = CFAbsoluteTimeGetCurrent();
	 if(startTime == 0)
	 startTime = time;
	 time = time - startTime;
	 
	 glMatrixMode(GL_MODELVIEW);
	 glLoadIdentity();
	 glTranslatef(0.0, 0.0, -30.0f);
	 //	glRotatef(50.0f * fmod(time, 360.0), 0.0, 1.0, 1.0);
	 */
	
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	float rele = m_ele * 0.01745329251994329547;// rads per deg
	float razi = m_azi * 0.01745329251994329547;// rads per deg
	
	
	btQuaternion rot(m_cameraUp,razi);
	
	
	btVector3 eyePos(0,0,0);
	eyePos[m_forwardAxis] = -m_cameraDistance;
	
	btVector3 forward(eyePos[0],eyePos[1],eyePos[2]);
	if (forward.length2() < SIMD_EPSILON)
	{
		forward.setValue(1.f,0.f,0.f);
	}
	btVector3 right = m_cameraUp.cross(forward);
	btQuaternion roll(right,-rele);
	
	eyePos = btMatrix3x3(rot) * btMatrix3x3(roll) * eyePos;
	
	m_cameraPosition[0] = eyePos.getX();
	m_cameraPosition[1] = eyePos.getY();
	m_cameraPosition[2] = eyePos.getZ();
	
	if (m_glutScreenWidth > m_glutScreenHeight) 
	{
		btScalar aspect = m_glutScreenWidth / (btScalar)m_glutScreenHeight;
		glFrustumf (-aspect, aspect, -1.0, 1.0, 1.0, 10000.0);
	} else 
	{
		btScalar aspect = m_glutScreenHeight / (btScalar)m_glutScreenWidth;
		glFrustumf (-1.0, 1.0, -aspect, aspect, 1.0, 10000.0);
	}
	
	
    glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	lookAt(m_cameraPosition[0], m_cameraPosition[1], m_cameraPosition[2], 
		   m_cameraTargetPosition[0], m_cameraTargetPosition[1], m_cameraTargetPosition[2], 
		   m_cameraUp.getX(),m_cameraUp.getY(),m_cameraUp.getZ());
	
	
	//
	// Touch screen support
	//
	// touch screen coordinates go from 0, 0 in the upper left corner to
	// 320, 480 in the lower right corner
	TouchScreen = GetValuesTouchScreen();
	
	// the center of the ray coordinates are located in the middle of the 
	// screen ... in the x direction the values range from -9875..9875 in x direction and
	// 15.000..-15000 in the y direction
	
	
	
	if(TouchScreen->TouchesEnd == false)
	{
		
		AppDisplayText->DisplayText(0, 10, 0.4f, RGBA(255,255,255,255), "touchesBegan: X: %3.2f Y: %3.2f Count: %3.2f Tab Count %3.2f", 
									TouchScreen->LocationXTouchesBegan, TouchScreen->LocationYTouchesBegan, TouchScreen->CountTouchesBegan, TouchScreen->TapCountTouchesBegan);
		AppDisplayText->DisplayText(0, 14, 0.4f, RGBA(255,255,255,255), "touchesMoved: X: %3.2f Y: %3.2f Count: %3.2f Tab Count %3.2f", 
									TouchScreen->LocationXTouchesMoved, TouchScreen->LocationYTouchesMoved, TouchScreen->CountTouchesMoved, TouchScreen->TapCountTouchesMoved);
		AppDisplayText->DisplayText(0, 18, 0.4f, RGBA(255,255,255,255), "Ray: X: %3.2f Y: %3.2f Z: %3.2f", Ray.getX(), Ray.getY(), Ray.getZ());
		
	}
	
	return true;
 	static struct timeval time = {0,0};
	struct timeval currTime = {0,0};
 
 	frames++;
	gettimeofday(&currTime, NULL); // gets the current time passed since the last frame in seconds
	
	btScalar deltaTime = 0.f;
	
	if (currTime.tv_usec - time.tv_usec) 
	{
		deltaTime = (currTime.tv_usec - time.tv_usec) / 1000000.0f;
		
		frameRate = ((float)frames)/(deltaTime);
		AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "fps: %3.2f, deltaTime = %3.2f", frameRate,deltaTime);
		time = currTime;
		frames = 0;
	}
	deltaTime = 1./60.f;
	if (sDynamicsWorld)
		sDynamicsWorld->stepSimulation(deltaTime,4);
	
	return true;
}

btRigidBody* pickedBody = 0;//for deactivation state
btPoint2PointConstraint* PickConstraint = 0;
int gPickingConstraintId = 0;
btVector3 gOldPickingPos;
float gOldPickingDist  = 0.f;


bool CShell::RenderScene()
{
	float worldMat[16];
	for (int i=0;i<numBodies;i++)
	{
		sBoxBodies[i]->getCenterOfMassTransform().getOpenGLMatrix(worldMat);
		glPushMatrix();
		glMultMatrixf(worldMat);
		
		
		//if(TouchScreen->TouchesEnd == false)
		{			
			btVector3 CameraPosition = m_cameraPosition;
			
			btCollisionWorld::ClosestRayResultCallback rayCallback(CameraPosition, Ray);
		
			// CountTouchesMoved shows how many fingers are moved ... if there is one finger or more moved this is 
			// 1 or higher
			// while CountTouchesBegan shows how many fingers have touched the sreen when the gesture started
			if (sDynamicsWorld)// && (TouchScreen->CountTouchesMoved >= 1))
			{
				Ray = GetRayTo(TouchScreen->LocationXTouchesBegan, TouchScreen->LocationYTouchesBegan, 
							   1.0f, 10000.0f,m_cameraUp, m_cameraPosition, 
							   m_cameraTargetPosition);
				
				sDynamicsWorld->rayTest(CameraPosition, Ray, rayCallback);
				if (rayCallback.hasHit())
				{
					AppDisplayText->DisplayText(0, 22, 0.4f, RGBA(255,255,255,255), "RayHit!");
					
					btRigidBody* body = btRigidBody::upcast(rayCallback.m_collisionObject);
					if (body)
					{
						body->setActivationState(ACTIVE_TAG);
						btVector3 impulse = Ray;
						impulse.normalize();
						float impulseStrength = 10.f;
						impulse *= impulseStrength;
						btVector3 relPos = rayCallback.m_hitPointWorld - body->getCenterOfMassPosition();
						body->applyImpulse(impulse,relPos);
					}
				}
			}
		}
		
		

		const float verts[] =
		{
			1.0f, 1.0f,-1.0f,	
			-1.0f, 1.0f,-1.0f,	
			-1.0f, 1.0f, 1.0f,	
			1.0f, 1.0f, 1.0f,	

			1.0f,-1.0f, 1.0f,	
			-1.0f,-1.0f, 1.0f,	
			-1.0f,-1.0f,-1.0f,	
			1.0f,-1.0f,-1.0f,	

			1.0f, 1.0f, 1.0f,	
			-1.0f, 1.0f, 1.0f,	
			-1.0f,-1.0f, 1.0f,	
			1.0f,-1.0f, 1.0f,	

			1.0f,-1.0f,-1.0f,	
			-1.0f,-1.0f,-1.0f,	
			-1.0f, 1.0f,-1.0f,	
			1.0f, 1.0f,-1.0f,	

			1.0f, 1.0f,-1.0f,	
			1.0f, 1.0f, 1.0f,	
			1.0f,-1.0f, 1.0f,	
			1.0f,-1.0f,-1.0f,

			-1.0f, 1.0f, 1.0f,	
			-1.0f, 1.0f,-1.0f,	
			-1.0f,-1.0f,-1.0f,	
			-1.0f,-1.0f, 1.0f
		};

		glEnableClientState(GL_VERTEX_ARRAY);
    
		glColor4f(0, 1, 0, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
		glColor4f(1, 0, 1, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts + 12);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
		glColor4f(0, 0, 1, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts + 24);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
		glColor4f(1, 1, 0, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts + 36);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
		glColor4f(1, 0, 0, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts + 48);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
		glColor4f(0, 1, 1, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts + 60);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	
		glPopMatrix();
	}
	
	// show text on the display
	AppDisplayText->DisplayDefaultTitle("Kick Cubes :-)", "", eDisplayTextLogoIMG);
	
	AppDisplayText->Flush();	
	
	return true;
}

