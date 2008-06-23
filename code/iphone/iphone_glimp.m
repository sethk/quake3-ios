/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#include <sys/param.h>
#include "../client/client.h"
#include "iphone_glimp.h"
#include "iphone_local.h"
#include "../renderer/tr_local.h"

#define MAX_ARRAY_SIZE		1024

static GLenum _GLimp_beginmode;
static float _GLimp_texcoords[MAX_ARRAY_SIZE][2];
static float _GLimp_vertexes[MAX_ARRAY_SIZE][3];
static float _GLimp_colors[MAX_ARRAY_SIZE][4];
static GLuint _GLimp_numverts;
static qboolean _GLimp_texcoordbuffer;
static qboolean _GLimp_colorbuffer;

#ifndef NDEBUG

#ifdef QGL_LOG_GL_CALLS
unsigned QGLLogGLCalls = 1;

extern FILE *
QGLDebugFile(void)
{
	return stderr;
}
#endif // QGL_LOG_GL_CALLS

unsigned int QGLBeginStarted = 0;

#ifdef QGL_CHECK_GL_ERRORS
void
QGLCheckError(const char *message)
{
    GLenum error;
    static unsigned int errorCount = 0;

	error = _glGetError();
	if (error != GL_NO_ERROR)
	{
        if (errorCount == 100)
            Com_Printf("100 GL errors printed ... disabling further error reporting.\n");
        else if (errorCount < 100)
		{
            if (errorCount == 0)
                fprintf(stderr, "BREAK ON QGLErrorBreak to stop at the GL errors\n");
            fprintf(stderr, "OpenGL Error(%s): 0x%04x\n", message, (int)error);
            QGLErrorBreak();
        }
        ++errorCount;
    }
}

#endif // QGL_CHECK_GL_ERRORS

#endif // NDEBUG

void
qglBegin(GLenum mode)
{
	assert(!QGLBeginStarted);
	QGLBeginStarted = qtrue;
	_GLimp_beginmode = mode;
	_GLimp_numverts = 0;
	_GLimp_texcoordbuffer = qfalse;
	_GLimp_colorbuffer = qfalse;
}

void
qglDrawBuffer(GLenum mode)
{
	if (mode != GL_BACK)
		UNIMPL();
}

void
qglEnd(void)
{
	assert(QGLBeginStarted);
	QGLBeginStarted = qfalse;

	if (_GLimp_texcoordbuffer)
	{
		qglTexCoordPointer(2, GL_FLOAT, sizeof(_GLimp_texcoords[0]), _GLimp_texcoords);
		qglEnableClientState(GL_TEXTURE_COORD_ARRAY);
	}
	else
		qglDisableClientState(GL_TEXTURE_COORD_ARRAY);

	if (_GLimp_colorbuffer)
	{
		qglColorPointer(4, GL_FLOAT, sizeof(_GLimp_colors[0]), _GLimp_colors);
		qglEnableClientState(GL_COLOR_ARRAY);
	}
	else
		qglDisableClientState(GL_COLOR_ARRAY);

	qglVertexPointer(3, GL_FLOAT, sizeof(_GLimp_vertexes[0]), _GLimp_vertexes);
	qglEnableClientState(GL_VERTEX_ARRAY);
	qglDrawArrays(GL_TRIANGLES, 0, _GLimp_numverts);
}

void
qglColor4f(GLfloat r, GLfloat g, GLfloat b, GLfloat a)
{
	GLfloat v[4] = {r, g, b, a};

	qglColor4fv(v);
}

void
qglColor4fv(GLfloat *v)
{
	if (QGLBeginStarted)
	{
		assert(_GLimp_numverts < MAX_ARRAY_SIZE);
		bcopy(v, _GLimp_colors[_GLimp_numverts], sizeof(_GLimp_colors[0]));
		_GLimp_colorbuffer = qtrue;
	}
	else
	{
		glColor4f(v[0], v[1], v[2], v[3]);
#ifdef QGL_CHECK_GL_ERRORS
		QGLCheckError("glColor4fv");
#endif // QGL_CHECK_GL_ERRORS
	}
}

void
qglTexCoord2f(GLfloat s, GLfloat t)
{
	GLfloat v[2] = {s, t};

	qglTexCoord2fv(v);
}

void
qglTexCoord2fv(GLfloat *v)
{
	assert(_GLimp_numverts < MAX_ARRAY_SIZE);
	bcopy(v, _GLimp_texcoords[_GLimp_numverts], sizeof(_GLimp_texcoords[0]));
	_GLimp_texcoordbuffer = qtrue;
}

void
qglVertex3f(GLfloat x, GLfloat y, GLfloat z)
{
	GLfloat v[3] = {x, y, z};

	qglVertex3fv(v);
}

void
qglVertex3fv(GLfloat *v)
{
	assert(_GLimp_numverts < MAX_ARRAY_SIZE);
	bcopy(v, _GLimp_vertexes[_GLimp_numverts++], sizeof(_GLimp_vertexes[0]));

	if (_GLimp_beginmode == IPHONE_QUADS && /*(_GLimp_numverts - 4) % 5 == 0*/ _GLimp_numverts == 4)
	{
		assert(_GLimp_numverts < MAX_ARRAY_SIZE - 2);
		bcopy(_GLimp_vertexes[_GLimp_numverts - 4],
				_GLimp_vertexes[_GLimp_numverts],
				sizeof(_GLimp_vertexes[0]));
		bcopy(_GLimp_texcoords[_GLimp_numverts - 4],
				_GLimp_texcoords[_GLimp_numverts],
				sizeof(_GLimp_texcoords[0]));
		bcopy(_GLimp_vertexes[_GLimp_numverts - 2],
				_GLimp_vertexes[_GLimp_numverts + 1],
				sizeof(_GLimp_vertexes[0]));
		bcopy(_GLimp_texcoords[_GLimp_numverts - 2],
				_GLimp_texcoords[_GLimp_numverts + 1],
				sizeof(_GLimp_texcoords[0]));
		_GLimp_numverts+= 2;
	}
}

void
qglCallList(GLuint list)
{
	UNIMPL();
}

void
GLimp_SetGamma(unsigned char red[256], unsigned char green[256], unsigned char blue[256])
{
	UNIMPL();
}

void
GLimp_Init(void)
{
	ri.Printf(PRINT_ALL, "Initializing OpenGL subsystem\n");

	bzero(&glConfig, sizeof(glConfig));
	glConfig.isFullscreen = qfalse;
#ifdef GL_ROTATE
	glConfig.vidWidth = IPHONE_HORIZ_YRES;
	glConfig.vidHeight = IPHONE_XRES;
#else
	glConfig.vidWidth = IPHONE_XRES;
	glConfig.vidHeight = IPHONE_VERT_YRES;
#endif // GL_ROTATE
	glConfig.windowAspect = (float)glConfig.vidWidth / glConfig.vidHeight;
	glConfig.colorBits = IPHONE_BPP;
	glConfig.depthBits = IPHONE_DEPTH_BPP;
	glConfig.stencilBits = 0;

	GLimp_SetMode();

    ri.Printf(PRINT_ALL, "------------------\n");

	Q_strncpyz(glConfig.vendor_string, (const char *)qglGetString(GL_VENDOR), sizeof(glConfig.vendor_string));
	Q_strncpyz(glConfig.renderer_string, (const char *)qglGetString(GL_RENDERER), sizeof(glConfig.renderer_string));
	Q_strncpyz(glConfig.version_string, (const char *)qglGetString(GL_VERSION), sizeof(glConfig.version_string));
	Q_strncpyz(glConfig.extensions_string,
			(const char *)qglGetString(GL_EXTENSIONS),
			sizeof(glConfig.extensions_string));

	qglLockArraysEXT = qglLockArrays;
	qglUnlockArraysEXT = qglUnlockArrays;

	glConfig.textureCompression = TC_NONE;
}

void
GLimp_LogComment(char *comment)
{
}

void
qglLockArrays(GLint i, GLsizei size)
{
	//UNIMPL();
}

void
qglUnlockArrays(void)
{
	//UNIMPL();
}

void
qglArrayElement(GLint i)
{
	UNIMPL();
}
