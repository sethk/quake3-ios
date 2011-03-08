/*
 *
 * Quake3Arena iPad Port by Alexander Pick
 * based on iPhone Quake 3 by Seth Kingsley
 *
 */

#ifndef IPHONE_LOCAL_H
#define IPHONE_LOCAL_H

#include <stdio.h>

#include "../game/q_shared.h"
#include "../qcommon/qcommon.h"

#define UNIMPL()	Com_Printf("%s(): Unimplemented\n", __FUNCTION__)

void Sys_QueEvent(int time, sysEventType_t type, int value, int value2, int ptrLength, void *ptr);
void Sys_QueEventEx(int time, sysEventType_t type, int value, int value2, int value3, int ptrLength, void *ptr);

#endif // IPHONE_LOCAL_H
