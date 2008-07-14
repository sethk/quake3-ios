/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#ifndef IPHONE_LOCAL_H
#define IPHONE_LOCAL_H

#include <stdio.h>

#define UNIMPL()	Com_Printf("%s(): Unimplemented\n", __FUNCTION__)

#ifdef QGL_CHECK_GL_ERRORS
void QGLErrorBreak(void);
#endif // QGL_CHECK_GL_ERRORS

void GLimp_SetMode(void);
void GLimp_ReleaseGL(void);

#endif // IPHONE_LOCAL_H
