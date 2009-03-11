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
int numBodies = 10;

//////////////////////////////////

//#include "Log.h"
#include "App.h"
#include "Mathematics.h"
#include "GraphicsDevice.h"
#include "UI.h"
#include "Macros.h"
#include "Accelerometer.h"


#include <stdio.h>
#include <sys/time.h>

CDisplayText * AppDisplayText;
int iCurrentTick = 0, iStartTick = 0, iFps = 0, iFrames = 0;

#define kAccelerometerFrequency		30.0 //Hz
#define kFilteringFactor			0.1


int frames;
float frameRate;

Accel* gAccel;


bool CShell::InitApplication()
{
//	LOGFUNC("InitApplication()");
	
	gAccel = [Accel alloc];
	
	[gAccel SetupAccelerometer: kAccelerometerFrequency];
	
	
	AppDisplayText = new CDisplayText;  
	
	if(AppDisplayText->SetTextures(WindowHeight, WindowWidth))
//		LOG("Display text textures loaded", Logger::LOG_DATA);
				printf("Display text textures loaded\n");


	sCollisionConfig = new btDefaultCollisionConfiguration();
	
	sBroadphase = new btDbvtBroadphase();
	
	sCollisionDispatcher = new btCollisionDispatcher(sCollisionConfig);
	sConstraintSolver = new btSequentialImpulseConstraintSolver;
	sDynamicsWorld = new btDiscreteDynamicsWorld(sCollisionDispatcher,sBroadphase,sConstraintSolver,sCollisionConfig);
	sDynamicsWorld->setGravity(btVector3(0,-10,0));
	
	btBoxShape* worldBoxShape = new btBoxShape(btVector3(10,10,10));
	///create 6 planes/half spaces
	for (int i=0;i<6;i++)
	{
		btTransform groundTransform;
		groundTransform.setIdentity();
		groundTransform.setOrigin(btVector3(0,10,0));
		btVector4 planeEq;
		worldBoxShape->getPlaneEquation(planeEq,i);
		
		btCollisionShape* groundShape = new btStaticPlaneShape(-planeEq,planeEq[3]);
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
		bodyTransform.setOrigin(btVector3(0,10+i*3,0));
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
		
		//most applications shouldn't disable deactivation, but for this demo it is better.
		boxBody->setActivationState(DISABLE_DEACTIVATION);
		//add the body to the dynamics world
		sDynamicsWorld->addRigidBody(boxBody);
	}
	
	return true;
}

bool CShell::QuitApplication()
{
	AppDisplayText->ReleaseTextures();
	
	delete AppDisplayText;
	
	[gAccel release];

	
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


bool CShell::UpdateScene()
{
	
    glEnable(GL_DEPTH_TEST);
	glClearColor(0.3f, 0.3f, 0.4f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// Set the OpenGL projection matrix
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	MATRIX	MyPerspMatrix;
	MatrixPerspectiveFovRH(MyPerspMatrix, f2vt(70), f2vt(((float) 320 / (float) 480)), f2vt(0.1f), f2vt(1000.0f), 0);
	glMultMatrixf(MyPerspMatrix.f);
	
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
		frameRate = ((float)frames/(TimeInterval));
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(0.0, -10.0, -30.0f);
	
	double AccelerometerVector[3];
	[gAccel GetAccelerometerVector:(double *) AccelerometerVector];
	
	AppDisplayText->DisplayText(0, 6, 0.4f, RGBA(255,255,255,255), "Accelerometer Vector: %3.2f, %3.2f, %3.2f, frameRate=%f", AccelerometerVector[0], AccelerometerVector[1], AccelerometerVector[2],frameRate);
	
	float deltaTime = 1.f/60.f;
	float scaling=20.f;
	
	if (sDynamicsWorld)
	{
		
		if (frameRate < 0.f)
			frameRate = deltaTime;
		if (frameRate > 1.f)
			frameRate = deltaTime;
		
		sDynamicsWorld->setGravity(btVector3(AccelerometerVector[0]*scaling,AccelerometerVector[1]*scaling,AccelerometerVector[2]*scaling));
		sDynamicsWorld->stepSimulation(frameRate, 2);//deltaTime);
		{
			static int i=0;
			if (i<10)
			{
				i++;
				CProfileManager::dumpAll();
			}
		}
	}

	return true;
}


bool CShell::RenderScene()
{
	float worldMat[16];
	for (int i=0;i<numBodies;i++)
	{
	sBoxBodies[i]->getCenterOfMassTransform().getOpenGLMatrix(worldMat);
	glPushMatrix();
	glMultMatrixf(worldMat);

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
	AppDisplayText->DisplayDefaultTitle("Falling Cubes", "", eDisplayTextLogoIMG);
	
	AppDisplayText->Flush();	
	
	return true;
}

