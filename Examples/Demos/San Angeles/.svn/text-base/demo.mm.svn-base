/* San Angeles Observation OpenGL ES version example
 * Copyright 2004-2005 Jetro Lauha
 * All rights reserved.
 * Web: http://iki.fi/jetro/
 *
 * This source is free software; you can redistribute it and/or
 * modify it under the terms of EITHER:
 *   (1) The GNU Lesser General Public License as published by the Free
 *       Software Foundation; either version 2.1 of the License, or (at
 *       your option) any later version. The text of the GNU Lesser
 *       General Public License is included with this source in the
 *       file LICENSE-LGPL.txt.
 *   (2) The BSD-style license that is included with this source in
 *       the file LICENSE-BSD.txt.
 *
 * This source is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the files
 * LICENSE-LGPL.txt and LICENSE-BSD.txt for more details.
 *
 * $Id: demo.c,v 1.10 2005/02/08 20:54:39 tonic Exp $
 * $Revision: 1.10 $
 */
#include <stdlib.h>

//#define FIXEDPOINTENABLE

//#define INDEXEDTRIANGLELIST

#include "GraphicsDevice.h"
#include "Mathematics.h"
#include "UI.h"
#include "App.h"
#include "Macros.h"
#include "Camera.h"
#include "MemoryManager.h"

#include "Geometry.h"

#include "demo.h"
#include "shapes.h"
#include "cams.h"

extern int gAppAlive;

// Total run length is 20 * camera track base unit length (see cams.h).
#define RUN_LENGTH  (20 * CAMTRACK_LEN)
#undef PI
#define PI 3.1415926535897932f
//#define RANDOM_UINT_MAX 65535

typedef struct
{
	int NumDrawCalls;
	int NumOfTriangles;
	int NumOfVertices;
}Statistics;
Statistics Stats;

//CFrustum *Frustum;

static unsigned long sRandomSeed = 0;

static void seedRandom(unsigned long seed)
{
    sRandomSeed = seed;
}

static unsigned long randomUInt()
{
    sRandomSeed = sRandomSeed * 0x343fd + 0x269ec3;
    return sRandomSeed >> 16;
}

#ifdef FIXEDPOINTENABLE

// Capped conversion from float to fixed.
static long floatToFixed(float value)
{
    if (value < -32768) value = -32768;
    if (value > 32767) value = 32767;
    return (long)(value * 65536);
}
#endif

#ifdef FIXEDPOINTENABLE
	#define FIXED(value) floatToFixed(value)
#else
	#define FIXED(value) (value)
#endif


// Definition of one GL object in this demo.
typedef struct 
{
    /* Vertex array and color array are enabled for all objects, so their
     * pointers must always be valid and non-NULL. Normal array is not
     * used by the ground plane, so when its pointer is NULL then normal
     * array usage is disabled.
     *
     * Vertex array is supposed to use GL_FIXED datatype and stride 0
     * (i.e. tightly packed array). Color array is supposed to have 4
     * components per color with GL_UNSIGNED_BYTE datatype and stride 0.
     * Normal array is supposed to use GL_FIXED datatype and stride 0.
     */
    VERTTYPE *vertexArray;
    GLubyte *colorArray;
    VERTTYPE *normalArray;
    GLint vertexComponents; 

#ifdef INDEXEDTRIANGLELIST
    GLsizei IndexCount;
	unsigned short *IndexList;
    GLsizei VertexCount;
#else
    GLsizei VertexCount;
#endif
	//unsigned byte* IndexList;
	//	CSphere *CullSphere;
	//	CAABB *AABBox;

} GLOBJECT;


static long sStartTick = 0;
static long sTick = 0;

static int sCurrentCamTrack = 0;
static long sCurrentCamTrackStartTick = 0;
static long sNextCamTrackStartTick = 0x7fffffff;

static GLOBJECT *sSuperShapeObjects[SUPERSHAPE_COUNT] = { NULL };
static GLOBJECT *sGroundPlane = NULL;


typedef struct {
    float x, y, z;
} DEMOVECTOR3;

DEMOVECTOR3 vec;

static void freeGLObject(GLOBJECT *object)
{
    if (object == NULL)
        return;
	if(object->normalArray)
		free(object->normalArray);
    
	free(object->colorArray);

//	free(object->AABBox);
//	free(object->CullSphere);
#ifdef INDEXEDTRIANGLELIST	
	free(object->IndexList);
	// this is allocated in createSuperShape ... not really a clean solution here
	free(object->vertexArray);
#else
	free(object->vertexArray);
#endif
    free(object);
}


static GLOBJECT * newGLObject(
#ifdef INDEXEDTRIANGLELIST
							  long indices,
#else
							  long vertices, 
#endif							  
							  int vertexComponents,
                              bool useNormalArray)
{
    GLOBJECT *result;
    result = (GLOBJECT *)malloc(sizeof(GLOBJECT));
    if (result == NULL)
        return NULL;
	
#ifdef INDEXEDTRIANGLELIST
    result->vertexComponents = vertexComponents;

	result->IndexCount = indices;

    result->IndexList = (unsigned short *)malloc(indices * sizeof(unsigned short));
	
	// can't tell the number of vertices here so allocate later
//    result->vertexArray = (VERTTYPE *)malloc(vertices * vertexComponents * sizeof(VERTTYPE));

    result->colorArray = (GLubyte *)malloc(indices * 4 * sizeof(GLubyte));
	
	if (useNormalArray)
    {
        result->normalArray = (VERTTYPE *)malloc(indices * 3 * sizeof(VERTTYPE));
    }
    else
        result->normalArray = NULL;
#else	
    result->vertexComponents = vertexComponents;
    result->vertexArray = (VERTTYPE *)malloc(vertices * vertexComponents * sizeof(VERTTYPE));
    result->colorArray = (GLubyte *)malloc(vertices * 4 * sizeof(GLubyte));
	
	if (useNormalArray)
    {
        result->normalArray = (VERTTYPE *)malloc(vertices * 3 * sizeof(VERTTYPE));
    }
    else
        result->normalArray = NULL;

#endif	
	
//	result->AABBox = (CAABB *) malloc(sizeof(CAABB));
//	result->CullSphere = (CSphere *) malloc(sizeof(CSphere));
	
	if (
#ifdef INDEXEDTRIANGLELIST
        result->IndexList == NULL ||
#else
		result->vertexArray == NULL ||
#endif
        result->colorArray == NULL ||
        (useNormalArray && result->normalArray == NULL))
    {
        freeGLObject(result);
        return NULL;
    }
	
		
    return result;
}

void GetStats(int &NumDrawCalls, int &NumOfTriangles, int &NumOfVertices)
{
	NumDrawCalls = Stats.NumDrawCalls;
	NumOfTriangles = Stats.NumOfTriangles;
	NumOfVertices = Stats.NumOfVertices;
}


static void drawGLObject(GLOBJECT *object)
{
    assert(object != NULL);

#ifdef FIXEDPOINTENABLE
    glVertexPointer(object->vertexComponents, GL_FIXED,
                    0, object->vertexArray);
#else
    glVertexPointer(object->vertexComponents, GL_FLOAT,
                    0, object->vertexArray);
#endif

    glColorPointer(4, GL_UNSIGNED_BYTE, 0, object->colorArray);

    if (object->normalArray)
    {
	#ifdef FIXEDPOINTENABLE
        glNormalPointer(GL_FIXED, 0, object->normalArray);
	#else
        glNormalPointer(GL_FLOAT, 0, object->normalArray);
	#endif
        glEnableClientState(GL_NORMAL_ARRAY);
    }
    else
        glDisableClientState(GL_NORMAL_ARRAY);

#ifdef INDEXEDTRIANGLELIST	
    glDrawElements(GL_TRIANGLES, object->IndexCount, GL_UNSIGNED_SHORT, object->IndexList);
#else	
    glDrawArrays(GL_TRIANGLES, 0, object->VertexCount);
#endif
	
	Stats.NumDrawCalls += 1;
	Stats.NumOfVertices += object->VertexCount;
	Stats.NumOfTriangles += object->VertexCount / 3;
}

/*
static bool cullGLObject(GLOBJECT *object)
{
	VECTOR3 SphereCenter = object->CullSphere->GetCenter();
	VERTTYPE SphereRadius = object->CullSphere->GetRadius();
	
	// the sphere center needs to be on the negative side plus sphere radius should 
	// stay positive as long as it is in the frustum
	if((Frustum->GetNearPlane().DistanceToPlane(SphereCenter) + SphereRadius) < 0)
		return true;
	else if((Frustum->GetFarPlane().DistanceToPlane(SphereCenter) + SphereRadius) < 0)
		return true;
	else if((Frustum->GetRightPlane().DistanceToPlane(SphereCenter) + SphereRadius) < 0)
		return true;
	else if((Frustum->GetLeftPlane().DistanceToPlane(SphereCenter) + SphereRadius) < 0)
		return true;
	else if((Frustum->GetBottomPlane().DistanceToPlane(SphereCenter) + SphereRadius) < 0)
		return true;
	else if((Frustum->GetTopPlane().DistanceToPlane(SphereCenter) + SphereRadius) < 0)
		return true;

	return false;
}
*/

static void vector3Sub(DEMOVECTOR3 *dest, DEMOVECTOR3 *v1, DEMOVECTOR3 *v2)
{
    dest->x = v1->x - v2->x;
    dest->y = v1->y - v2->y;
    dest->z = v1->z - v2->z;
}


static void superShapeMap(DEMOVECTOR3 *point, float r1, float r2, float t, float p)
{
    // sphere-mapping of supershape parameters
    point->x = (float)(cosf(t) * cosf(p) / r1 / r2);
    point->y = (float)(sinf(t) * cosf(p) / r1 / r2);
    point->z = (float)(sinf(p) / r2);
}



static float ssFunc(const float t, const float *p)
{
    return (float)(pow(pow(_ABS(cos(p[0] * t / 4)) / p[1], p[4]) +
                       pow(_ABS(sin(p[0] * t / 4)) / p[2], p[5]), 1 / p[3]));
}


// Creates and returns a supershape object.
// Based on Paul Bourke's POV-Ray implementation.
// http://astronomy.swin.edu.au/~pbourke/povray/supershape/
static GLOBJECT * createSuperShape(const float *params)
{
    const int resol1 = (int)params[SUPERSHAPE_PARAMS - 3];
    const int resol2 = (int)params[SUPERSHAPE_PARAMS - 2];
    // latitude 0 to pi/2 for no mirrored bottom
    // (latitudeBegin==0 for -pi/2 to pi/2 originally)
    const int latitudeBegin = resol2 / 4;
    const int latitudeEnd = resol2 / 2;    // non-inclusive
    const int longitudeCount = resol1;
    const int latitudeCount = latitudeEnd - latitudeBegin;
    const long triangleCount = longitudeCount * latitudeCount * 2;
#ifdef INDEXEDTRIANGLELIST
    const long indizes = triangleCount * 3;
#else
    const long vertices = triangleCount * 3;
#endif
    GLOBJECT *result;
    float baseColor[3];
    int a, longitude, latitude;
    long currentVertex, currentQuad;

#ifdef INDEXEDTRIANGLELIST
    result = newGLObject(indizes, 3, 1);
	
	// vertex soup to indexed triangle conversion
	VertexLookup vl = Vl_createVertexLookup();
#else
    result = newGLObject(vertices, 3, 1);
#endif
	if (result == NULL)
        return NULL;

    for (a = 0; a < 3; ++a)
        baseColor[a] = ((randomUInt() % 155) + 100) / 255.f;

    currentQuad = 0;
    currentVertex = 0;
	
	DEMOVECTOR3 pa, pb, pc, pd;
	DEMOVECTOR3 v1, v2, n;
	float ca;


    // longitude -pi to pi
    for (longitude = 0; longitude < longitudeCount; ++longitude)
    {

        // latitude 0 to pi/2
        for (latitude = latitudeBegin; latitude < latitudeEnd; ++latitude)
        {
            float t1 = -PI + longitude * 2 * PI / resol1;
            float t2 = -PI + (longitude + 1) * 2 * PI / resol1;
            float p1 = -PI / 2 + latitude * 2 * PI / resol2;
            float p2 = -PI / 2 + (latitude + 1) * 2 * PI / resol2;
            float r0, r1, r2, r3;

            r0 = ssFunc(t1, params);
            r1 = ssFunc(p1, &params[6]);
            r2 = ssFunc(t2, params);
            r3 = ssFunc(p2, &params[6]);

            if (r0 != 0 && r1 != 0 && r2 != 0 && r3 != 0)
            {
                int i;
                //float lenSq, invLenSq;

                superShapeMap(&pa, r0, r1, t1, p1);
                superShapeMap(&pb, r2, r1, t2, p1);
                superShapeMap(&pc, r2, r3, t2, p2);
                superShapeMap(&pd, r0, r3, t1, p2);

                // kludge to set lower edge of the object to fixed level
                if (latitude == latitudeBegin + 1)
                    pa.z = pb.z = 0;

                vector3Sub(&v1, &pb, &pa);
                vector3Sub(&v2, &pd, &pa);

                // Calculate normal with cross product.
                /*   i    j    k      i    j
                 * v1.x v1.y v1.z | v1.x v1.y
                 * v2.x v2.y v2.z | v2.x v2.y
                 */

                n.x = v1.y * v2.z - v1.z * v2.y;
                n.y = v1.z * v2.x - v1.x * v2.z;
                n.z = v1.x * v2.y - v1.y * v2.x;

                /* Pre-normalization of the normals is disabled here because
                 * they will be normalized anyway later due to automatic
                 * normalization (GL_NORMALIZE). It is enabled because the
                 * objects are scaled with glScale.
                 */
                /*
                lenSq = n.x * n.x + n.y * n.y + n.z * n.z;
                invLenSq = (float)(1 / sqrt(lenSq));
                n.x *= invLenSq;
                n.y *= invLenSq;
                n.z *= invLenSq;
                */

                ca = pa.z + 0.5f;

                for (i = currentVertex * 3;
                     i < (currentVertex + 6) * 3;
                     i += 3)
                {
                    result->normalArray[i] = FIXED(n.x);
                    result->normalArray[i + 1] = FIXED(n.y);
                    result->normalArray[i + 2] = FIXED(n.z);
                }
				for (i = currentVertex * 4;
                     i < (currentVertex + 6) * 4;
					i += 4)
				{
					int a, color[3];
                    for (a = 0; a < 3; ++a)
                    {
                        color[a] = (int)(ca * baseColor[a] * 255);
                        if (color[a] > 255) color[a] = 255;
                    }
                    result->colorArray[i] = (GLubyte)color[0];
                    result->colorArray[i + 1] = (GLubyte)color[1];
                    result->colorArray[i + 2] = (GLubyte)color[2];
                    result->colorArray[i + 3] = 0;
                }

#ifdef INDEXEDTRIANGLELIST
				result->IndexList[currentVertex] = Vl_getIndex(vl, (const float *)&pa);
                ++currentVertex;
				result->IndexList[currentVertex] = Vl_getIndex(vl, (const float *)&pb);
                ++currentVertex;
				result->IndexList[currentVertex] = Vl_getIndex(vl, (const float *)&pd);
                ++currentVertex;
				result->IndexList[currentVertex] = Vl_getIndex(vl, (const float *)&pb);
                ++currentVertex;
				result->IndexList[currentVertex] = Vl_getIndex(vl, (const float *)&pc);
                ++currentVertex;
				result->IndexList[currentVertex] = Vl_getIndex(vl, (const float *)&pd);
                ++currentVertex;
#else			
                result->vertexArray[currentVertex * 3] = FIXED(pa.x);
                result->vertexArray[currentVertex * 3 + 1] = FIXED(pa.y);
                result->vertexArray[currentVertex * 3 + 2] = FIXED(pa.z);
                ++currentVertex;
                result->vertexArray[currentVertex * 3] = FIXED(pb.x);
                result->vertexArray[currentVertex * 3 + 1] = FIXED(pb.y);
                result->vertexArray[currentVertex * 3 + 2] = FIXED(pb.z);
                ++currentVertex;
                result->vertexArray[currentVertex * 3] = FIXED(pd.x);
                result->vertexArray[currentVertex * 3 + 1] = FIXED(pd.y);
                result->vertexArray[currentVertex * 3 + 2] = FIXED(pd.z);
                ++currentVertex;
                result->vertexArray[currentVertex * 3] = FIXED(pb.x);
                result->vertexArray[currentVertex * 3 + 1] = FIXED(pb.y);
                result->vertexArray[currentVertex * 3 + 2] = FIXED(pb.z);
                ++currentVertex;
                result->vertexArray[currentVertex * 3] = FIXED(pc.x);
                result->vertexArray[currentVertex * 3 + 1] = FIXED(pc.y);
                result->vertexArray[currentVertex * 3 + 2] = FIXED(pc.z);
                ++currentVertex;
                result->vertexArray[currentVertex * 3] = FIXED(pd.x);
                result->vertexArray[currentVertex * 3 + 1] = FIXED(pd.y);
                result->vertexArray[currentVertex * 3 + 2] = FIXED(pd.z);
                ++currentVertex;
#endif
				
            } // r0 && r1 && r2 && r3
            ++currentQuad;
        } // latitude
    } // longitude

#ifdef INDEXEDTRIANGLELIST
	// get the number of vertices
	result->VertexCount = Vl_getVcount(vl);
	result->IndexCount = currentVertex;

	// get a pointer to the pool of vertex data
	const float * vert= (GLfloat*)Vl_getVertices(vl);

	// allocate an vertex array
	result->vertexArray = (VERTTYPE *)malloc(result->VertexCount * result->vertexComponents * sizeof(VERTTYPE));
	
	// fill up the vertex array
	memcpy(result->vertexArray, vert, result->VertexCount * result->vertexComponents * sizeof(VERTTYPE));
	
	// release the vertex lookup interface
	Vl_releaseVertexLookup(vl);		
#else	
	// Set number of vertices in object to the actual amount created.
    result->VertexCount = currentVertex;
#endif
	
	
	//
	// optimize triangle list
	//
/*	
	//
	// create normals
	//
	for(int i = 0; i < result->VertexCount; i++)
	{
		pa.x = vert[0];
		pa.y = vert[1];
		pa.z = vert[2];
		pb.x = vert[3];
		pb.y = vert[4];
		pb.z = vert[5];
		pd.x = vert[6];
		pd.y = vert[7];
		pd.z = vert[8];
		vert+=3;
		
		vector3Sub(&v1, &pb, &pa);
		vector3Sub(&v2, &pd, &pa);
		
		n.x = v1.y * v2.z - v1.z * v2.y;
		n.y = v1.z * v2.x - v1.x * v2.z;
		n.z = v1.x * v2.y - v1.y * v2.x;
		
		result->normalArray[i] = (n.x);
		result->normalArray[i + 1] = (n.y);
		result->normalArray[i + 2] = (n.z);

		ca = pa.z + 0.5f;
		
		int a, color[3];
		for (a = 0; a < 3; ++a)
		{
			color[a] = (int)(ca * baseColor[a] * 255);
			if (color[a] > 255) color[a] = 255;
		}
		result->colorArray[i] = (GLubyte)color[0];
		result->colorArray[i + 1] = (GLubyte)color[1];
		result->colorArray[i + 2] = (GLubyte)color[2];
		result->colorArray[i + 3] = 0;

 }
*/		
	// create AABB box
	//result->AABBox->ComputeAABB((const VECTOR3 *)result->vertexArray, (const int) result->VertexCount);
	
	// create sphere from AABB box
	//result->CullSphere->CreateSphereFromAABB(*result->AABBox);
	
	return result;
}


static GLOBJECT * createGroundPlane()
{
    const int scale = 32;
    const int yBegin = -15, yEnd = 15;    // ends are non-inclusive
    const int xBegin = -15, xEnd = 15;
    const long triangleCount = (yEnd - yBegin) * (xEnd - xBegin) * 2;
    const long vertices = triangleCount * 3;
    GLOBJECT *result;
    int x, y;
    long currentVertex, currentQuad;

#ifdef INDEXEDTRIANGLELIST
	GLuint vertexComponents = 3;
#else
	GLuint vertexComponents = 2;
#endif
	
    result = newGLObject(vertices, vertexComponents, 0);
    if (result == NULL)
        return NULL;
	
#ifdef INDEXEDTRIANGLELIST
	// vertex soup to indexed triangle list conversion
	VertexLookup vl = Vl_createVertexLookup();
#endif
	
    currentQuad = 0;
    currentVertex = 0;
//	DEMOVECTOR3 vec;

    for (y = yBegin; y < yEnd; ++y)
    {
        for (x = xBegin; x < xEnd; ++x)
        {
            GLubyte color;
            int i, a;
            color = (GLubyte)((randomUInt() & 0x5f) + 81);  // 101 1111
            for (i = currentVertex * 4; i < (currentVertex + 6) * 4; i += 4)
            {
                result->colorArray[i] = color;
                result->colorArray[i + 1] = color;
                result->colorArray[i + 2] = color;
                result->colorArray[i + 3] = 0;
            }

            // Axis bits for quad triangles:
            // x: 011100 (0x1c), y: 110001 (0x31)  (clockwise)
            // x: 001110 (0x0e), y: 100011 (0x23)  (counter-clockwise)
            for (a = 0; a < 6; ++a)
            {
                //const int xm = x + ((0x1c >> a) & 1);
                //const int ym = y + ((0x31 >> a) & 1);
                const int xm = x + ((28 >> a) & 1);
                const int ym = y + ((49 >> a) & 1);
                const float m = (float)(cos(xm * 2) * sin(ym * 4) * 0.75f);
#ifdef INDEXEDTRIANGLELIST
				// this is a vector with a x and y component ... no z component
				vec.x = FIXED(xm * scale + m);
				vec.y = FIXED(ym * scale + m);
				vec.z = 0.25f;
				result->IndexList[currentVertex] = Vl_getIndex(vl,(const float *)&vec);
#else
                result->vertexArray[currentVertex * 2] = FIXED(xm * scale + m);
                result->vertexArray[currentVertex * 2 + 1] = FIXED(ym * scale + m);
#endif
                ++currentVertex;
            }
            ++currentQuad;
        }
    }
#ifdef INDEXEDTRIANGLELIST
	// get the number of vertices
	result->VertexCount = Vl_getVcount(vl);
	result->IndexCount = currentVertex;
	
	// get a pointer to the pool of vertex data
	const float * vert= (GLfloat*)Vl_getVertices(vl);
	
	// allocate an vertex array
	result->vertexArray = (VERTTYPE *)malloc(result->VertexCount * result->vertexComponents * sizeof(VERTTYPE));
	
	// fill up the vertex array
	memcpy(result->vertexArray, vert, result->VertexCount * result->vertexComponents * sizeof(VERTTYPE));
	
	// release the vertex lookup interface
	Vl_releaseVertexLookup(vl);		
#else	
	result->VertexCount = currentVertex;	
#endif
	
    return result;
}


static void drawGroundPlane()
{
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ZERO, GL_SRC_COLOR);
    glDisable(GL_LIGHTING);

    drawGLObject(sGroundPlane);

    glEnable(GL_LIGHTING);
    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
}


static void drawFadeQuad()
{
    static const VERTTYPE quadVertices[] = 
	{
        -f2vt(1.0f), -f2vt(1.0f),
         f2vt(1.0f), -f2vt(1.0f),
        -f2vt(1.0f),  f2vt(1.0f),
         f2vt(1.0f), -f2vt(1.0f),
         f2vt(1.0f),  f2vt(1.0f),
        -f2vt(1.0f),  f2vt(1.0f)
    };

    const int beginFade = sTick - sCurrentCamTrackStartTick;
    const int endFade = sNextCamTrackStartTick - sTick;
    const int minFade = beginFade < endFade ? beginFade : endFade;

    if (minFade < 1024)
    {
	#ifdef FIXEDPOINTENABLE
        const VERTTYPE fadeColor = minFade << 6;
	#else
        const VERTTYPE fadeColor = X2F(minFade << 6);
	#endif
        glColor4f(fadeColor, fadeColor, fadeColor, 0);
		
        glDisable(GL_DEPTH_TEST);
        glEnable(GL_BLEND);
        glBlendFunc(GL_ZERO, GL_SRC_COLOR);
        glDisable(GL_LIGHTING);

        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();

        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();

        glDisableClientState(GL_COLOR_ARRAY);
        glDisableClientState(GL_NORMAL_ARRAY);
        glVertexPointer(2, VERTTYPEENUM, 0, quadVertices);
        glDrawArrays(GL_TRIANGLES, 0, 6);

        glEnableClientState(GL_COLOR_ARRAY);

        glMatrixMode(GL_MODELVIEW);

        glEnable(GL_LIGHTING);
        glDisable(GL_BLEND);
        glEnable(GL_DEPTH_TEST);
    }
}


// Called from the app framework.
void appInit()
{
    int a;

    glEnable(GL_NORMALIZE);
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glShadeModel(GL_FLAT);

    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glEnable(GL_LIGHT1);
    glEnable(GL_LIGHT2);

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
	
	// allocate heap for frustum planes
//	Frustum = (CFrustum *) malloc(sizeof(CFrustum));
	
    seedRandom(15);

    for (a = 0; a < (int)SUPERSHAPE_COUNT; ++a)
    {
        sSuperShapeObjects[a] = createSuperShape(sSuperShapeParams[a]);
        assert(sSuperShapeObjects[a] != NULL);
    }
    sGroundPlane = createGroundPlane();
    assert(sGroundPlane != NULL);
}


// Called from the app framework.
void appDeinit()
{
    int a;
    for (a = 0; a < (int)SUPERSHAPE_COUNT; ++a)
        freeGLObject(sSuperShapeObjects[a]);
	

    freeGLObject(sGroundPlane);
	
//	free(Frustum);
}


static void gluPerspective(GLfloat fovy, GLfloat aspect,
                           GLfloat zNear, GLfloat zFar)
{
    GLfloat xmin, xmax, ymin, ymax;

    ymax = zNear * (GLfloat)tan(fovy * PI / 360);
    ymin = -ymax;
    xmin = ymin * aspect;
    xmax = ymax * aspect;
	
    glFrustumf(f2vt(xmin), f2vt(xmax),
                f2vt(ymin), f2vt(ymax),
               f2vt(zNear), f2vt(zFar));
}


static void prepareFrame(int width, int height)
{
    glViewport(0, 0, height, width);

    glClearColor(f2vt(0.1f),
                  f2vt(0.2f),
                  f2vt(0.3f), f2vt(1.0f));
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
	gluPerspective(80, (float)height / width, 0.3f, 75.0f);
	glRotatef(f2vt(90), 0, 0, f2vt(1));
	
	MATRIX	PerspMatrix;
	
#ifdef FIXEDPOINTENABLE
	glGetFixedv(GL_PROJECTION_MATRIX, PerspMatrix.f);
#else
	glGetFloatv(GL_PROJECTION_MATRIX, PerspMatrix.f);
#endif
	
//	Frustum->ExtractPlanes(PerspMatrix, true); 

	glMatrixMode(GL_MODELVIEW);

    glLoadIdentity();
	
	Stats.NumDrawCalls = 0;
	Stats.NumOfTriangles = 0;
	Stats.NumOfVertices = 0;
}


void appConfigureLightAndMaterial()
{
#ifdef FIXEDPOINTENABLE
    static VERTTYPE light0Position[] = { (-0x40000), (0x10000), (0x10000), 0 };
    static VERTTYPE light0Diffuse[] = {( 0x10000), (0x6666), 0, (0x10000) };
    static VERTTYPE light1Position[] = { (0x10000), (-0x20000), (-0x10000), 0 };
    static VERTTYPE light1Diffuse[] = { (0x11eb), (0x23d7), (0x5999), (0x10000) };
    static VERTTYPE light2Position[] = { (-0x10000), 0, (-0x40000), 0 };
    static VERTTYPE light2Diffuse[] = { (0x11eb), (0x2b85), (0x23d7), (0x10000) };
    static VERTTYPE materialSpecular[] = { (0x10000), (0x10000), (0x10000), (0x10000) };
#else
    static VERTTYPE light0Position[] = { X2F(-0x40000), X2F(0x10000), X2F(0x10000), 0 };
    static VERTTYPE light0Diffuse[] = {X2F( 0x10000), X2F(0x6666), 0, X2F(0x10000) };
    static VERTTYPE light1Position[] = { X2F(0x10000), X2F(-0x20000), X2F(-0x10000), 0 };
    static VERTTYPE light1Diffuse[] = { X2F(0x11eb), X2F(0x23d7), X2F(0x5999), X2F(0x10000) };
    static VERTTYPE light2Position[] = { X2F(-0x10000), 0, X2F(-0x40000), 0 };
    static VERTTYPE light2Diffuse[] = { X2F(0x11eb), X2F(0x2b85), X2F(0x23d7), X2F(0x10000) };
    static VERTTYPE materialSpecular[] = { X2F(0x10000), X2F(0x10000), X2F(0x10000), X2F(0x10000) };
#endif
    glLightfv(GL_LIGHT0, GL_POSITION, light0Position);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, light0Diffuse);
    glLightfv(GL_LIGHT1, GL_POSITION, light1Position);
    glLightfv(GL_LIGHT1, GL_DIFFUSE, light1Diffuse);
    glLightfv(GL_LIGHT2, GL_POSITION, light2Position);
    glLightfv(GL_LIGHT2, GL_DIFFUSE, light2Diffuse);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, materialSpecular);

    glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, f2vt(60));
    glEnable(GL_COLOR_MATERIAL);
}


static void drawModels(float zScale)
{
    const int translationScale = 9;
    int x, y;

    seedRandom(9);

    glScalef(f2vt(1), f2vt(1), f2vt(zScale));

    for (y = -5; y <= 5; ++y)
    {
        for (x = -5; x <= 5; ++x)
        {
            float buildingScale;
            VERTTYPE fixedScale;

            int curShape = randomUInt() % SUPERSHAPE_COUNT;
            buildingScale = sSuperShapeParams[curShape][SUPERSHAPE_PARAMS - 1];
            fixedScale = f2vt(buildingScale);

            glPushMatrix();
            glTranslatef(f2vt(x * translationScale),
                         f2vt(y * translationScale),
                         0);
            glRotatef(f2vt((randomUInt() % 360)), 0, 0, f2vt(1));
            glScalef(fixedScale, fixedScale, fixedScale);

			MATRIX	ViewMatrix;
	
		#ifdef FIXEDPOINTENABLE
			glGetFixedv(GL_MODELVIEW_MATRIX, ViewMatrix.f);
		#else
			glGetFloatv(GL_MODELVIEW_MATRIX, ViewMatrix.f);
		#endif
		
			MATRIX	ProjMatrix;
	
		#ifdef FIXEDPOINTENABLE
			glGetFixedv(GL_PROJECTION_MATRIX, ProjMatrix.f);
		#else
			glGetFloatv(GL_PROJECTION_MATRIX, ProjMatrix.f);
		#endif

//			if(cullGLObject(sSuperShapeObjects[curShape]))
				drawGLObject(sSuperShapeObjects[curShape]);

            glPopMatrix();
        }
    }

    for (x = -2; x <= 2; ++x)
    {
        const int shipScale100 = translationScale * 500;
        const int offs100 = x * shipScale100 + (sTick % shipScale100);
        float offs = offs100 * 0.01f;
        VERTTYPE fixedOffs = f2vt(offs);
        glPushMatrix();
        glTranslatef(fixedOffs, f2vt(-4), f2vt(2));
		
//		if(cullGLObject(sSuperShapeObjects[SUPERSHAPE_COUNT - 1]))
			drawGLObject(sSuperShapeObjects[SUPERSHAPE_COUNT - 1]);

        glPopMatrix();
        glPushMatrix();
        glTranslatef(f2vt(-4), fixedOffs, f2vt(4));
        glRotatef(f2vt(90), 0, 0, f2vt(1));
		
//		if(cullGLObject(sSuperShapeObjects[SUPERSHAPE_COUNT - 1]))
			drawGLObject(sSuperShapeObjects[SUPERSHAPE_COUNT - 1]);
        glPopMatrix();
    }
}


/* Following gluLookAt implementation is adapted from the
 * Mesa 3D Graphics library. http://www.mesa3d.org
 */
static void gluLookAt(GLfloat eyex, GLfloat eyey, GLfloat eyez,
	              GLfloat centerx, GLfloat centery, GLfloat centerz,
	              GLfloat upx, GLfloat upy, GLfloat upz)
{
    GLfloat m[16];
    GLfloat x[3], y[3], z[3];
    GLfloat mag;

    /* Make rotation matrix */

    /* Z vector */
    z[0] = eyex - centerx;
    z[1] = eyey - centery;
    z[2] = eyez - centerz;
    mag = (float)sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2]);
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

    mag = (float)sqrt(x[0] * x[0] + x[1] * x[1] + x[2] * x[2]);
    if (mag) {
        x[0] /= mag;
        x[1] /= mag;
        x[2] /= mag;
    }

    mag = (float)sqrt(y[0] * y[0] + y[1] * y[1] + y[2] * y[2]);
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
    {
        int a;
        VERTTYPE fixedM[16];
        for (a = 0; a < 16; ++a)
            fixedM[a] = f2vt(m[a]);
        glMultMatrixf(fixedM);
    }

    /* Translate Eye to Origin */
    glTranslatef(f2vt(-eyex),
                 f2vt(-eyey),
                 f2vt(-eyez));
}


static void camTrack()
{
    float lerp[5];
    float eX, eY, eZ, cX, cY, cZ;
    float trackPos;
    CAMTRACK *cam;
    long currentCamTick;
    int a;

    if (sNextCamTrackStartTick <= sTick)
    {
        ++sCurrentCamTrack;
        sCurrentCamTrackStartTick = sNextCamTrackStartTick;
    }
    sNextCamTrackStartTick = sCurrentCamTrackStartTick +
                             sCamTracks[sCurrentCamTrack].len * CAMTRACK_LEN;

    cam = &sCamTracks[sCurrentCamTrack];
    currentCamTick = sTick - sCurrentCamTrackStartTick;
    trackPos = (float)currentCamTick / (CAMTRACK_LEN * cam->len);

    for (a = 0; a < 5; ++a)
        lerp[a] = (cam->src[a] + cam->dest[a] * trackPos) * 0.01f;

    if (cam->dist)
    {
        float dist = cam->dist * 0.1f;
        cX = lerp[0];
        cY = lerp[1];
        cZ = lerp[2];
        eX = cX - (float)cos(lerp[3]) * dist;
        eY = cY - (float)sin(lerp[3]) * dist;
        eZ = cZ - lerp[4];
    }
    else
    {
        eX = lerp[0];
        eY = lerp[1];
        eZ = lerp[2];
        cX = eX + (float)cos(lerp[3]);
        cY = eY + (float)sin(lerp[3]);
        cZ = eZ + lerp[4];
    }
    gluLookAt(eX, eY, eZ, cX, cY, cZ, 0, 0, 1);
}


// Called from the app framework.
/* The tick is current time in milliseconds, width and height
 * are the image dimensions to be rendered.
 */
void appRender(long tick, int width, int height)
{
    if (sStartTick == 0)
        sStartTick = tick;
    if (!gAppAlive)
        return;

    // Actual tick value is "blurred" a little bit.
    sTick = (sTick + tick - sStartTick) >> 1;

    // Terminate application after running through the demonstration once.
    if (sTick >= RUN_LENGTH)
    {
        gAppAlive = 0;
        return;
    }

    // Prepare OpenGL ES for rendering of the frame.
    prepareFrame(width, height);

    // Update the camera position and set the lookat.
    camTrack();
	
	glDisable(GL_CULL_FACE); /// switched off backface culling
	
	//glEnable(GL_CULL_FACE); /// switched on backface culling
	//glCullFace(GL_FRONT);

    // Draw the reflection by drawing models with negated Z-axis.
    glPushMatrix();
    drawModels(-1);
    glPopMatrix();

    // Blend the ground plane to the window.
    drawGroundPlane();

	// some of the models need culling off
	//glEnable(GL_CULL_FACE); /// switched on backface culling
	//glCullFace(GL_BACK);
	
    // Draw all the models normally.
    drawModels(1);

    // Draw fade quad over whole window (when changing cameras).
    drawFadeQuad();
}
