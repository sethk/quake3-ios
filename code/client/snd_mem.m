/*
===========================================================================
Copyright (C) 1999-2005 Id Software, Inc.

This file is part of Quake III Arena source code.

Quake III Arena source code is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.

Quake III Arena source code is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Foobar; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
===========================================================================
*/

/*****************************************************************************
 * name:		snd_mem.c
 *
 * desc:		sound caching
 *
 * $Archive: /MissionPack/code/client/snd_mem.c $
 *
 *****************************************************************************/

#include "snd_local.h"

#define DEF_COMSOUNDMEGS "8"

/*
===============================================================================

memory management

===============================================================================
*/

static	int inUse = 0;
static	int totalInUse = 0;

short *sfxScratchBuffer = NULL;
sfx_t *sfxScratchPointer = NULL;
int	   sfxScratchIndex = 0;

void	SND_free(sndBuffer *v) {

}

sndBuffer*	SND_malloc() {
	sndBuffer *v;

	return v;
}

void SND_setup() {

}

/*
===============================================================================

WAV loading

===============================================================================
*/

static	qbyte 	*last_chunk;
static	qbyte 	*iff_data;

static short GetLittleShort(void)
{
	short val = 0;

	return val;
}

static int GetLittleLong(void)
{
	int val = 0;
	return val;
}

static void FindNextChunk(char *name)
{

}

static void FindChunk(char *name)
{
	last_chunk = iff_data;
	FindNextChunk (name);
}

/*
============
GetWavinfo
============
*/
static wavinfo_t GetWavinfo (char *name, qbyte *wav, int wavlength)
{
	wavinfo_t	info;

	return info;
}


/*
================
ResampleSfx

resample / decimate to the current source rate
================
*/
static void ResampleSfx( sfx_t *sfx, int inrate, int inwidth, qbyte *data, qboolean compressed ) {

}

/*
================
ResampleSfx

resample / decimate to the current source rate
================
*/
static int ResampleSfxRaw( short *sfx, int inrate, int inwidth, int samples, qbyte *data ) {
	return 1; //outcount;
}


//=============================================================================

/*
==============
S_LoadSound

The filename may be different than sfx->name in the case
of a forced fallback of a player specific sound
==============
*/
qboolean S_LoadSound( sfx_t *sfx )
{
	char	*sdata;
	
	int		size;

	// player specific sounds are never directly loaded
	if ( sfx->soundName[0] == '*') {
		return qfalse;
	}

	//Com_Printf("%s\n", sfx->soundName);
	
	// load it in
	size = FS_ReadFile( sfx->soundName, (void **)&sdata );
	if ( !sdata ) {
		return qfalse;
	}

	sfx->lastTimeUsed = Com_Milliseconds()+1;

	sfx->soundLength = size;
	
	const char *buf_p = sdata;
	
	NSData *nBuf = [[NSData alloc] initWithBytes:buf_p length:size];
	
	AVAudioPlayer *sPlayer = [[AVAudioPlayer alloc] initWithData:nBuf error:nil];
	
	[nBuf release];	
	
	[sPlayer setDelegate:nil];
	
	sfx->sndPlayer = sPlayer;
	
	FS_FreeFile( sdata );

	return qtrue;
}

void S_DisplayFreeMemory() {
	Com_Printf("%d bytes free sound buffer memory, %d total used\n", inUse, totalInUse);
}
