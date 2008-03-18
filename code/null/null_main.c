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
// sys_null.h -- null system driver to aid porting efforts

#include <errno.h>
#include <stdio.h>
#include "../game/q_shared.h"
#include "../qcommon/qcommon.h"

int			sys_curtime;

qboolean stdin_active = qtrue;

//===================================================================

void Sys_BeginStreamedFile( fileHandle_t f, int readAhead ) {
}

void Sys_EndStreamedFile( fileHandle_t f ) {
}

int Sys_StreamedRead( void *buffer, int size, int count, fileHandle_t f ) {
	return fread( buffer, size, count, f );
}

void Sys_StreamSeek( fileHandle_t f, int offset, int origin ) {
	fseek( f, offset, origin );
}


//===================================================================


#if !IPHONE
void Sys_Mkdir ( const char *path ) {
}
#endif // !IPHONE

void Sys_Error (const char *error, ...) {
	va_list		argptr;

	printf ("Sys_Error: ");	
	va_start (argptr,error);
	vprintf (error,argptr);
	va_end (argptr);
	printf ("\n");

	exit (1);
}

void Sys_Quit (void) {
	exit (0);
}

void	Sys_UnloadGame (void) {
}

void	*Sys_GetGameAPI (void *parms) {
	return NULL;
}

char	*Sys_GetClipboardData( void ) {
	return NULL;
}

#if !IPHONE
int	Sys_Milliseconds (void) {
	return 0;
}
#endif // IPHONE

char	*Sys_FindFirst (char *path, unsigned musthave, unsigned canthave) {
	return NULL;
}

char	*Sys_FindNext (unsigned musthave, unsigned canthave) {
	return NULL;
}

void	Sys_FindClose (void) {
}

sysEvent_t	Sys_GetEvent( void ) {
	sysEvent_t event;

	bzero(&event, sizeof(event));
	return event;
}

void	* QDECL Sys_LoadDll( const char *name, char *fqpath , int (QDECL **entryPoint)(int, ...),
				  int (QDECL *systemcalls)(int, ...) )
{
	return NULL;
}

void	Sys_UnloadDll( void *dllHandle ) {
}

qboolean    Sys_CheckCD( void )
{
	return qtrue;
}

void	Sys_Print( const char *msg ) {
	fputs(msg, stdout);
}

void	Sys_Init (void) {
}


void	Sys_EarlyOutput( char *string ) {
	printf( "%s", string );
}

void	Sys_BeginProfiling( void ) {
}

qboolean Sys_LowPhysicalMemory() {
	return qfalse;
}

int main (int argc, char **argv) {
	char buf[1024] = "";
	unsigned i;

	for (i = 0; i < argc; ++i)
		strcat(buf, argv[i]);

	Com_Init (buf);

	while (1) {
		Com_Frame( );
	}

	return 0;
}


