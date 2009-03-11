#--------------------------------------------------------------------------
# Name         : content.mak
# Title        : Makefile to build content files
# Author       : Auto-generated
#
# Copyright    : 2007 by Imagination Technologies.  All rights reserved.
#              : No part of this software, either material or conceptual 
#              : may be copied or distributed, transmitted, transcribed,
#              : stored in a retrieval system or translated into any 
#              : human or computer language in any form by any means,
#              : electronic, mechanical, manual or other-wise, or 
#              : disclosed to third parties without the express written
#              : permission of VideoLogic Limited, Unit 8, HomePark
#              : Industrial Estate, King's Langley, Hertfordshire,
#              : WD4 8LZ, U.K.
#
# Description  : Makefile to build content files for demos in the PowerVR SDK
#
# Platform     :
#
# $Revision: 1.2 $
#--------------------------------------------------------------------------

#############################################################################
## Variables
#############################################################################

PVRTEXTOOL 	= ..\..\..\Utilities\PVRTexTool\PVRTexToolCL\Win32\PVRTexTool.exe
FILEWRAP 	= ..\..\..\Utilities\Filewrap\Win32\Filewrap.exe


MEDIAPATH = ../Media
CONTENTDIR = Content

#############################################################################
## Instructions
#############################################################################

TEXTURES = \
	LightTex.pvr \
	Stone.pvr

	

RESOURCES = \
	$(CONTENTDIR)/LightTex.cpp \
	$(CONTENTDIR)/Stone.cpp \
	$(CONTENTDIR)/LightingScene_float.cpp \
	$(CONTENTDIR)/LightingScene_fixed.cpp

all: resources 
	
help:
	@echo Valid targets are:
	@echo resources, textures, binary_shaders, clean
	@echo PVRTEXTOOL, FILEWRAP and VGPCOMPILER can be used to override the 
	@echo default paths to these utilities.

clean:
	-rm $(TEXTURES)
	-rm $(RESOURCES)
	
	
resources: 		$(CONTENTDIR) $(RESOURCES)
textures: 		$(TEXTURES)


$(CONTENTDIR):
	-mkdir $@

############################################################################
# Create textures
############################################################################

LightTex.pvr: $(MEDIAPATH)/LightTex.bmp
	$(PVRTEXTOOL) -m -fOGLPVRTC4 -i$(MEDIAPATH)/LightTex.bmp -o$@

Stone.pvr: $(MEDIAPATH)/Stone.bmp
	$(PVRTEXTOOL) -m -fOGLPVRTC4 -i$(MEDIAPATH)/Stone.bmp -o$@

############################################################################
# Create content files
############################################################################

$(CONTENTDIR)/LightTex.cpp: LightTex.pvr
	$(FILEWRAP)  -o $@ LightTex.pvr

$(CONTENTDIR)/Stone.cpp: Stone.pvr
	$(FILEWRAP)  -o $@ Stone.pvr

$(CONTENTDIR)/LightingScene_float.cpp: LightingScene_float.pod
	$(FILEWRAP)  -o $@ LightingScene_float.pod

$(CONTENTDIR)/LightingScene_fixed.cpp: LightingScene_fixed.pod
	$(FILEWRAP)  -o $@ LightingScene_fixed.pod


############################################################################
# End of file (content.mak)
############################################################################
