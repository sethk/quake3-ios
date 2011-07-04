# Quake3 -- iPhone Port
#
# Seth Kingsley, January 2008.
#
# Use `bsdmake' on OS X, `pmake' on GNU/Linux, and `make' on *BSD.
#
# TODO: Avoid relinking main binary because target name does not match
# linker output.

CODE_DIR = ${.CURDIR}/..

HEAVENLY?= /usr/local/share/iphone-filesystem

IPHONE_CC = /usr/local/bin/arm-apple-darwin-gcc
IPHONE_OBJC = /usr/local/bin/arm-apple-darwin-gcc
IPHONE_LDFLAGS = -L${HEAVENLY}/usr/lib
IPHONE_LDLIBS = ${HEAVENLY}/System/Library/Frameworks/OpenGLES.framework/OpenGLES \
		${HEAVENLY}/System/Library/Frameworks/UIKit.framework/UIKit \
		${HEAVENLY}/System/Library/Frameworks/Foundation.framework/Foundation \
		${HEAVENLY}/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation \
		${HEAVENLY}/System/Library/Frameworks/CoreSurface.framework/CoreSurface \
		${HEAVENLY}/System/Library/Frameworks/LayerKit.framework/LayerKit \
		${HEAVENLY}/System/Library/Frameworks/GraphicsServices.framework/GraphicsServices
IPHONE_SIMUL_LDLIBS = -framework OpenGL -framework Cocoa

NATIVE_ARCH!= arch
ARCH?= ${NATIVE_ARCH}

.PATH: ${CODE_DIR}/botlib ${CODE_DIR}/jpeg-6 ${CODE_DIR}/client ${CODE_DIR}/game ${CODE_DIR}/qcommon \
		${CODE_DIR}/renderer ${CODE_DIR}/null ${CODE_DIR}/server ${CODE_DIR}/unix ${CODE_DIR}/iphone \
		${CODE_DIR}/q3_ui ${CODE_DIR}/ui ${CODE_DIR}/cgame

SHARED_SRCS = q_math.c q_shared.c

BOTLIB_SRCS = be_aas_bspq3.c be_aas_cluster.c be_aas_debug.c be_aas_entity.c be_aas_file.c be_aas_main.c be_aas_move.c \
		be_aas_optimize.c be_aas_reach.c be_aas_route.c be_aas_routealt.c be_aas_sample.c be_ai_char.c be_ai_chat.c \
		be_ai_gen.c be_ai_goal.c be_ai_move.c be_ai_weap.c be_ai_weight.c be_ea.c be_interface.c l_crc.c l_libvar.c \
		l_log.c l_memory.c l_precomp.c l_script.c l_struct.c

JPEG_SRCS = jcapimin.c jccoefct.c jccolor.c jcdctmgr.c jchuff.c jcinit.c jcmainct.c jcmarker.c jcmaster.c jcomapi.c \
		jcparam.c jcphuff.c jcprepct.c jcsample.c jctrans.c jdapimin.c jdapistd.c jdatasrc.c jdcoefct.c jdcolor.c \
		jddctmgr.c jdhuff.c jdinput.c jdmainct.c jdmarker.c jdmaster.c jdpostct.c jdsample.c jerror.c jfdctflt.c \
		jidctflt.c jmemansi.c jmemmgr.c jutils.c

CLIENT_SRCS = cl_cgame.c cl_cin.c cl_console.c cl_input.c cl_keys.c cl_main.c cl_net_chan.c cl_parse.c cl_scrn.c \
		cl_ui.c snd_adpcm.c snd_dma.c snd_mem.c snd_mix.c snd_wavelet.c

COMMON_SRCS = cm_load.c cm_patch.c cm_polylib.c cm_test.c cm_trace.c cmd.c common.c cvar.c files.c huffman.c md4.c \
		msg.c net_chan.c unzip.c vm.c vm_interpreted.c

RENDERER_SRCS =	tr_animation.c tr_backend.c tr_bsp.c tr_cmds.c tr_curve.c tr_font.c tr_image.c tr_init.c tr_light.c \
		tr_main.c tr_marks.c tr_mesh.c tr_model.c tr_noise.c tr_scene.c tr_shade.c tr_shade_calc.c tr_shader.c \
		tr_shadows.c tr_sky.c tr_surface.c tr_world.c

NULL_SRCS = null_snddma.c

SERVER_SRCS = sv_bot.c sv_ccmds.c sv_client.c sv_game.c sv_init.c sv_main.c sv_net_chan.c sv_snapshot.c sv_world.c

UNIX_SRCS =	unix_net.c unix_shared.c unix_main.c

IPHONE_SRCS = iphone_input.m iphone_glimp.m iphone_glsmp_null.c iphone_main.m Q3Application.m Q3ScreenView.m

SRCS = ${BOTLIB_SRCS} ${JPEG_SRCS} ${CLIENT_SRCS} ${COMMON_SRCS} ${RENDERER_SRCS} ${NULL_SRCS} ${SERVER_SRCS} \
		${UNIX_SRCS} ${IPHONE_SRCS} ${SHARED_SRCS} ${EXTRA_SRCS}
OBJS = ${SRCS:C/.c$/.o/:C/.m$/.o/}

UI_SRCS = bg_misc.c	ui_addbots.c ui_atoms.c ui_cdkey.c ui_cinematics.c ui_confirm.c ui_connect.c ui_controls2.c \
		ui_credits.c ui_demo2.c ui_display.c ui_gameinfo.c ui_ingame.c ui_loadconfig.c ui_main.c ui_menu.c ui_mfield.c \
		ui_mods.c ui_network.c ui_options.c ui_playermodel.c ui_players.c ui_playersettings.c ui_preferences.c \
		ui_qmenu.c ui_removebots.c ui_saveconfig.c ui_serverinfo.c ui_servers2.c ui_setup.c ui_sound.c ui_sparena.c \
		ui_specifyserver.c ui_splevel.c ui_sppostgame.c ui_spskill.c ui_startserver.c ui_syscalls.c ui_team.c \
		ui_teamorders.c ui_video.c ${SHARED_SRCS}
UI_OBJS = ${UI_SRCS:C/.c$/.o/}

QAGAME_SRCS = ai_chat.c ai_cmd.c ai_dmnet.c ai_dmq3.c ai_main.c ai_team.c ai_vcmd.c bg_misc.c bg_pmove.c \
		bg_slidemove.c g_active.c g_arenas.c g_bot.c g_client.c g_cmds.c g_combat.c g_items.c g_main.c g_mem.c \
		g_misc.c g_missile.c g_mover.c g_session.c g_spawn.c g_svcmds.c g_syscalls.c g_target.c g_team.c g_trigger.c \
		g_utils.c g_weapon.c ${SHARED_SRCS}
QAGAME_OBJS = ${QAGAME_SRCS:C/.c$/.o/}

CGAME_SRCS = bg_misc.c bg_pmove.c bg_slidemove.c cg_consolecmds.c cg_draw.c cg_drawtools.c cg_effects.c cg_ents.c \
		cg_event.c cg_info.c cg_localents.c cg_main.c cg_marks.c cg_players.c cg_playerstate.c cg_predict.c \
		cg_scoreboard.c cg_servercmds.c cg_snapshot.c cg_syscalls.c cg_view.c cg_weapons.c ${SHARED_SRCS}
CGAME_OBJS = ${CGAME_SRCS:C/.c$/.o/}

LDFLAGS = ${EXTRA_LDFLAGS}
LDLIBS = -lobjc ${EXTRA_LDLIBS}

INCS = -I. -I${CODE_DIR}/qcommon -I${CODE_DIR}/renderer -I${CODE_DIR}/client -I${CODE_DIR}/iphone
DEFS = -DMACOS_X -DIPHONE -DBOTLIB -DDLL_ONLY -DC_ONLY -DSHLIB_SUFFIX="\"dylib\"" ${EXTRA_DEFS}
OPT_FLAGS = -fpascal-strings -fasm-blocks -fmessage-length=0
DEBUG_FLAGS = -O0 -g -fno-inline -fno-inline-functions -mfix-and-continue -DQGL_CHECK_GL_ERRORS
#DEBUG_FLAGS+= -DQGL_LOG_GL_CALLS
#DEBUG_FLAGS+= -DMEMDEBUG
#DEBUG_FLAGS+= -DDEBUG_KEEPALIVE
CFLAGS+= ${DEBUG_FLAGS} ${INCS} ${DEFS} ${OPT_FLAGS}
CFLAGS+= -fno-common ${DEBUG_FLAGS} ${INCS} ${DEFS} ${OPT_FLAGS}

RUN_FLAGS = +set developer 1 +set r_picmip 3
.PHONY: quake3

all: quake3-iphone

quake3-iphone:
	${MAKE} CC="${IPHONE_CC}" OBJC="${IPHONE_OBJC}" EXTRA_LDFLAGS="${IPHONE_LDFLAGS}" EXTRA_LDLIBS="${IPHONE_LDLIBS}" \
			MAKEOBJDIR="iphone-obj" EXTRA_SRCS="iphone_glimp_native.m" ARCH="arm" \
			quake3 uiarm.dylib qagamearm.dylib cgamearm.dylib
	[ -d iphone-obj/Quake3.app ] || mkdir -p iphone-obj/Quake3.app
	cp -p iphone-obj/quake3 iphone-obj/Quake3.app/Quake3
	cp -p Info.plist iphone-obj/Quake3.app

quake3-simul:
	${MAKE} MAKEOBJDIR="iphone-simul-obj" EXTRA_DEFS="-DIPHONE_SIMUL" EXTRA_LDLIBS="${IPHONE_SIMUL_LDLIBS}" \
			EXTRA_SRCS="iphone_glimp_simul.m" quake3 ui${ARCH}.dylib qagame${ARCH}.dylib cgame${ARCH}.dylib
	[ -d iphone-simul-obj/Quake3.app/Contents/MacOS ] || mkdir -p iphone-simul-obj/Quake3.app/Contents/MacOS
	cp -p iphone-simul-obj/quake3 iphone-simul-obj/Quake3.app/Contents/MacOS/Quake3
	cp -p Simul-Info.plist iphone-simul-obj/Quake3.app/Contents/Info.plist
	[ -d iphone-simul-obj/Quake3.app/Contents/Resources/English.lproj ] || \
			mkdir -p iphone-simul-obj/Quake3.app/Contents/Resources/English.lproj
	rm -rf iphone-simul-obj/Quake3.app/Contents/Resources/English.lproj/Quake3.nib
	cp -Rp Simul-Quake3.nib iphone-simul-obj/Quake3.app/Contents/Resources/English.lproj/Quake3.nib

quake3: ${OBJS}
	${CC} -o ${.TARGET} ${LDFLAGS} ${LDLIBS} ${OBJS}

ui${ARCH}.dylib: ${UI_OBJS}
	${CC} ${LDFLAGS} -dynamiclib -o ${.TARGET} ${UI_OBJS}

qagame${ARCH}.dylib: ${QAGAME_OBJS}
	${CC} ${LDFLAGS} -dynamiclib -o ${.TARGET} ${QAGAME_OBJS}

cgame${ARCH}.dylib: ${CGAME_OBJS}
	${CC} ${LDFLAGS} -dynamiclib -o ${.TARGET} ${CGAME_OBJS}

clean:
	rm -f iphone-obj/*
	rm -rf iphone-simul-obj/*

copy: quake3-iphone
	rsync -e ssh -rv --delete iphone-obj/Quake3.app root@${IPHONE_IP}:
	scp iphone-obj/uiarm.dylib iphone-obj/qagamearm.dylib iphone-obj/cgamearm.dylib root@${IPHONE_IP}:demoq3

copy-paks:
	scp demoq3/pak0.pk3 root@${IPHONE_IP}:demoq3

copy-simul: quake3-simul
	cp iphone-simul-obj/ui${ARCH}.dylib iphone-simul-obj/qagame${ARCH}.dylib iphone-simul-obj/cgame${ARCH}.dylib demoq3/

run:
	ssh -t root@${IPHONE_IP} Quake3.app/Quake3 ${RUN_FLAGS} \|\& tee quake3.log

run-simul: quake3-simul
	iphone-simul-obj/Quake3.app/Contents/MacOS/Quake3 ${RUN_FLAGS}

debug-simul: quake3-simul
	gdb iphone-simul-obj/Quake3.app/Contents/MacOS/Quake3

ssh:
	ssh root@${IPHONE_IP}
