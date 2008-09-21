/*
 * Quake3 -- iPhone Port
 *
 * Seth Kingsley, January 2008.
 */

#ifndef IPHONE_LOCAL_H
#define IPHONE_LOCAL_H

#include <stdio.h>

#include "../game/q_shared.h"
#include "../qcommon/qcommon.h"

#define UNIMPL()	Com_Printf("%s(): Unimplemented\n", __FUNCTION__)

void Sys_QueEvent(int time, sysEventType_t type, int value, int value2, int ptrLength, void *ptr);

#endif // IPHONE_LOCAL_H
