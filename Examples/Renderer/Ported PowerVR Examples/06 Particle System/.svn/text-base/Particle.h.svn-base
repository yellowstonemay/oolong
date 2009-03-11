/******************************************************************************

 @File         Particle.h

 @Title        Particle class for OGLESParticles.cpp

 @Copyright    Copyright (C) 2005 - 2008 by Imagination Technologies Limited.

 @Platform     Independant

 @Description  Requires the OGLESShell.

******************************************************************************/
//#include "OGLESTools.h"

#ifndef PVRT_FIXED_POINT_ENABLE
	#define vt2b(a) (unsigned char) (a)
#else
	#define vt2b(a) (unsigned char) (a>>16)
#endif

class CParticle
{
public:
	// Dynamic properties
	Vec3	m_fPosition;
	Vec3	m_fVelocity;
	Vec3	m_fColour;
	VERTTYPE	m_fAge;

	// Inherent properties
	VERTTYPE	m_fLifeTime;
	float		m_fMass;

	VERTTYPE	m_fSize;

	Vec3	m_fInitialColour;
	Vec3	m_fHalfwayColour;
	Vec3	m_fEndColor;

public:
	CParticle() { }	// Allow default construct
	CParticle(const Vec3 &fPos, const Vec3 &fVel, float fM, VERTTYPE fLife) :  m_fPosition(fPos), 
																					m_fVelocity(fVel), 
																					m_fAge(f2vt(0)), 
																					m_fLifeTime(fLife), 
																					m_fMass(fM), 
																					m_fSize(f2vt(0))  { }

	bool Step(VERTTYPE fDelta_t, Vec3 &aForce)
	{
		Vec3 fAccel;
		Vec3 fForce = aForce;

		if (m_fPosition.y < f2vt(0))
		{
			if(fDelta_t != f2vt(0.0))
			{
				fForce.y += VERTTYPEMUL(VERTTYPEMUL(VERTTYPEMUL(f2vt(0.5f),m_fVelocity.y),m_fVelocity.y),f2vt(m_fMass)) + f2vt(9.8f*m_fMass);
			}
		}

		VERTTYPE fInvMass = f2vt(1.0f/m_fMass);
		fAccel.x = f2vt(0.0f) + VERTTYPEMUL(fForce.x,fInvMass);
		fAccel.y = f2vt(-9.8f) + VERTTYPEMUL(fForce.y,fInvMass);
		fAccel.z = f2vt(0.0f) + VERTTYPEMUL(fForce.z,fInvMass);

		m_fVelocity.x += VERTTYPEMUL(fDelta_t,fAccel.x);
		m_fVelocity.y += VERTTYPEMUL(fDelta_t,fAccel.y);
		m_fVelocity.z += VERTTYPEMUL(fDelta_t,fAccel.z);

		m_fPosition.x += VERTTYPEMUL(fDelta_t,m_fVelocity.x);
		m_fPosition.y += VERTTYPEMUL(fDelta_t,m_fVelocity.y);
		m_fPosition.z += VERTTYPEMUL(fDelta_t,m_fVelocity.z);
		m_fAge += fDelta_t;

		if(m_fAge <= m_fLifeTime / 2)
		{
			VERTTYPE mu = f2vt(vt2f(m_fAge) / (vt2f(m_fLifeTime)/2.0f));
			m_fColour.x = VERTTYPEMUL((f2vt(1)-mu),m_fInitialColour.x) + VERTTYPEMUL(mu,m_fHalfwayColour.x);
			m_fColour.y = VERTTYPEMUL((f2vt(1)-mu),m_fInitialColour.y) + VERTTYPEMUL(mu,m_fHalfwayColour.y);
			m_fColour.z = VERTTYPEMUL((f2vt(1)-mu),m_fInitialColour.z) + VERTTYPEMUL(mu,m_fHalfwayColour.z);
		}
		else
		{
			VERTTYPE mu = f2vt((vt2f(m_fAge-m_fLifeTime)/2.0f) / (vt2f(m_fLifeTime)/2.0f));
			m_fColour.x = VERTTYPEMUL((f2vt(1)-mu),m_fHalfwayColour.x) + VERTTYPEMUL(mu,m_fEndColor.x);
			m_fColour.y = VERTTYPEMUL((f2vt(1)-mu),m_fHalfwayColour.y) + VERTTYPEMUL(mu,m_fEndColor.y);
			m_fColour.z = VERTTYPEMUL((f2vt(1)-mu),m_fHalfwayColour.z) + VERTTYPEMUL(mu,m_fEndColor.z);
		}

		return (m_fAge >= m_fLifeTime);
	}
};


