/*
Oolong Engine for the iPhone / iPod touch
Copyright (c) 2007-2008 Wolfgang Engel  http://code.google.com/p/oolongengine/

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose, 
including commercial applications, and to alter it and redistribute it freely, 
subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/

#import "Q3Accelerometer.h"

#define FILTERINGFACTOR 0.1

@implementation Q3Accelerometer

- (void) setupAccelerometer: (float) acclerometerFrequency
{
	//Configure and start accelerometer
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / acclerometerFrequency)];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
}



- (void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*) acceleration
{
	// use a basic low-pass filter to only keep the gravity in the accelerometer values
	_accelerometer[0] = acceleration.x * FILTERINGFACTOR + _accelerometer[0] * (1.0 - FILTERINGFACTOR);
	_accelerometer[1] = acceleration.y * FILTERINGFACTOR + _accelerometer[1] * (1.0 - FILTERINGFACTOR);
	_accelerometer[2] = acceleration.z * FILTERINGFACTOR + _accelerometer[2] * (1.0 - FILTERINGFACTOR);
}

- (void) accelerometerMatrix:(GLfloat *) matrix
{

	GLfloat length = sqrtf(_accelerometer[0] * _accelerometer[0] + _accelerometer[1] * _accelerometer[1] + _accelerometer[2] * _accelerometer[2]);

	//Clear matrix to be used to rotate from the current referential to one based on the gravity vector
	bzero(matrix, sizeof(matrix));
	matrix[15] = 1.0f;
	//matrix[3][3] = 1.0;
		
	//Setup first matrix column as gravity vector
	matrix[0] = _accelerometer[0] / length;
	matrix[1] = _accelerometer[1] / length;
	matrix[2] = _accelerometer[2] / length;
		
	//Setup second matrix column as an arbitrary vector in the plane perpendicular to the gravity vector {Gx, Gy, Gz} defined by by the equation "Gx * x + Gy * y + Gz * z = 0" in which we arbitrarily set x=0 and y=1
	matrix[4] = 0.0;
	matrix[5] = 1.0;
	matrix[6] = -_accelerometer[1] / _accelerometer[2];
	length = sqrtf(matrix[4] * matrix[4] + matrix[5] * matrix[5] + matrix[6] * matrix[6]);
	matrix[4] /= length;
	matrix[5] /= length;
	matrix[6] /= length;
		
	//Setup third matrix column as the cross product of the first two
	matrix[8] = matrix[1] * matrix[6] - matrix[2] * matrix[5];
	matrix[9] = matrix[4] * matrix[2] - matrix[6] * matrix[0];
	matrix[10] = matrix[0] * matrix[5] - matrix[1] * matrix[4];
}

- (void) accelerometerVector:(double *) accelValue;
{
	// the vector is read-only, so make a copy of it and do not expose a pointer to it
	accelValue[0] = (double)_accelerometer[0];
	accelValue[1] = (double)_accelerometer[1];
	accelValue[2] = (double)_accelerometer[2];
}

@end
