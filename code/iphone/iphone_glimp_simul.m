/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, February 2008.
 */

#include "iphone_local.h"
#include "iphone_glimp.h"
#import	"Q3Application.h"
#import	"Q3ScreenView.h"

#import <OpenGL/CGLTypes.h>

static CGLContextObj cglContext;

#ifdef QGL_CHECK_GL_ERRORS
void
QGLErrorBreak(void)
{
	abort();
}
#endif // QGL_CHECK_GL_ERRORS

void
GLimp_SetMode(void)
{
	cglContext = [[[(Q3Application *)NSApp screenView] openGLContext] CGLContextObj];
}

void
GLimp_AcquireGL(void)
{
	Com_Printf("GLimp_AcquireGL()\n");
	CGLSetCurrentContext(cglContext);
}

void
GLimp_ReleaseGL(void)
{
	CGLSetCurrentContext(NULL);
	Com_Printf("GLimp_ReleaseGL()\n");
}

void
GLimp_EndFrame(void)
{
	GLimp_ReleaseGL();
	[[[(Q3Application *)NSApp screenView] openGLContext] flushBuffer];
}

void
GLimp_Shutdown(void)
{
}
