/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#import	"iphone_glimp.h"

#include "tr_local.h"

qboolean
GLimp_SpawnRenderThread(void (*function)(void))
{
	return qfalse;
}

void *
GLimp_RendererSleep(void)
{
	return NULL;
}

void
GLimp_FrontEndSleep(void)
{
}

void
GLimp_WakeRenderer(void *data)
{
}
