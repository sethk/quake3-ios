/*
 *
 * Quake3Arena iPad Port by Alexander Pick
 * based on iPhone Quake 3 by Seth Kingsley
 *
 */

#include <sys/param.h>
#include "../client/client.h"
#include "ipad_glimp.h"
#include "ipad_local.h"
#include "../renderer/tr_local.h"

#import	"Q3Application.h"
#import	"Q3ScreenView.h"

#define MAX_ARRAY_SIZE		1024

static Q3ScreenView *_screenView;
static EAGLContext *_context;
static GLenum _GLimp_beginmode;
static float _GLimp_texcoords[MAX_ARRAY_SIZE][2];
static float _GLimp_vertexes[MAX_ARRAY_SIZE][3];
static float _GLimp_colors[MAX_ARRAY_SIZE][4];
static GLuint _GLimp_numInputVerts, _GLimp_numOutputVerts;
static qboolean _GLimp_texcoordbuffer;
static qboolean _GLimp_colorbuffer;

unsigned int QGLBeginStarted = 0;

#ifndef NDEBUG

#ifdef QGL_LOG_GL_CALLS
unsigned QGLLogGLCalls = 1;

extern FILE *
QGLDebugFile(void)
{
	return stderr;
}
#endif // QGL_LOG_GL_CALLS

#ifdef QGL_CHECK_GL_ERRORS
void
QGLErrorBreak(void)
{
}

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
	_GLimp_numInputVerts = _GLimp_numOutputVerts = 0;
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
	GLenum mode;

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

	if (_GLimp_beginmode == IPHONE_QUADS)
		mode = GL_TRIANGLES;
	else if (_GLimp_beginmode == IPHONE_POLYGON)
		assert(0);
	else
		mode = _GLimp_beginmode;

	qglDrawArrays(mode, 0, _GLimp_numOutputVerts);
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
		assert(_GLimp_numOutputVerts < MAX_ARRAY_SIZE);
		bcopy(v, _GLimp_colors[_GLimp_numOutputVerts], sizeof(_GLimp_colors[0]));
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
	assert(_GLimp_numOutputVerts < MAX_ARRAY_SIZE);
	bcopy(v, _GLimp_texcoords[_GLimp_numOutputVerts], sizeof(_GLimp_texcoords[0]));
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
	assert(_GLimp_numOutputVerts < MAX_ARRAY_SIZE);
	bcopy(v, _GLimp_vertexes[_GLimp_numOutputVerts++], sizeof(_GLimp_vertexes[0]));
	++_GLimp_numInputVerts;

	if (_GLimp_beginmode == IPHONE_QUADS && _GLimp_numInputVerts % 4 == 0)
	{
		assert(_GLimp_numOutputVerts < MAX_ARRAY_SIZE - 2);
		bcopy(_GLimp_vertexes[_GLimp_numOutputVerts - 4],
				_GLimp_vertexes[_GLimp_numOutputVerts],
				sizeof(_GLimp_vertexes[0]));
		bcopy(_GLimp_texcoords[_GLimp_numOutputVerts - 4],
				_GLimp_texcoords[_GLimp_numOutputVerts],
				sizeof(_GLimp_texcoords[0]));
		bcopy(_GLimp_vertexes[_GLimp_numOutputVerts - 2],
				_GLimp_vertexes[_GLimp_numOutputVerts + 1],
				sizeof(_GLimp_vertexes[0]));
		bcopy(_GLimp_texcoords[_GLimp_numOutputVerts - 2],
				_GLimp_texcoords[_GLimp_numOutputVerts + 1],
				sizeof(_GLimp_texcoords[0]));
		_GLimp_numOutputVerts+= 2;
	}
	else if (_GLimp_beginmode == IPHONE_POLYGON)
		assert(0);
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
	Q3Application *application = (Q3Application *)[Q3Application sharedApplication];

	ri.Printf(PRINT_ALL, "Initializing OpenGL subsystem\n");

	bzero(&glConfig, sizeof(glConfig));

	_screenView = application.screenView;
	_context = _screenView.context;

	//GLimp_SetMode(application.deviceRotation);
	GLimp_SetMode(90.00);

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
GLimp_SetMode(float rotation)
{
	UIView *superview = _screenView.superview;
	CGRect superviewBounds = superview.bounds, frame;

	if (rotation == 0 || rotation == 180)
	{
		frame.size.width = superviewBounds.size.width;
		frame.size.height = frame.size.width * (3 / 4.0);
		frame.origin.x = superviewBounds.origin.x;
		frame.origin.y = (superviewBounds.size.height - frame.size.height) / 2;
	}
	else
		frame = superviewBounds;

	_screenView.frame = frame;

	glConfig.isFullscreen = qtrue;
 	/*if (rotation == 0 || rotation == 180)
 	{
 		glConfig.vidWidth = frame.size.width;
 		glConfig.vidHeight = frame.size.height;
 	}
 	else
 	{*/
 		glConfig.vidWidth = frame.size.height;
 		glConfig.vidHeight = frame.size.width;
 	//}
	glConfig.windowAspect = (float)glConfig.vidWidth / glConfig.vidHeight;
	glConfig.colorBits = [_screenView numColorBits];
	glConfig.depthBits = [_screenView numDepthBits];
	glConfig.stencilBits = 0;
	glConfig.vidRotation = rotation;

	if (cls.uiStarted)
	{
		cls.glconfig = glConfig;
		VM_Call(uivm, UI_UPDATE_GLCONFIG);
	}
	
	if (cls.state == CA_ACTIVE)
	{
		cls.glconfig = glConfig;
		VM_Call(cgvm, CG_UPDATE_GLCONFIG);
	}
}

void
GLimp_AcquireGL(void)
{
#ifdef IPHONE_USE_THREADS
	[EAGLContext setCurrentContext:_context];
#endif // IPHONE_USE_THREADS
}

void
GLimp_LogComment(char *comment)
{
}

void
GLimp_ReleaseGL(void)
{
#ifdef IPHONE_USE_THREADS
	[EAGLContext setCurrentContext:nil];
#endif // IPHONE_USE_THREADS
}

void
GLimp_EndFrame(void)
{
	GLimp_ReleaseGL();
	[_screenView swapBuffers];
}

void
GLimp_Shutdown(void)
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
