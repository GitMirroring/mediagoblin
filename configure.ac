#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([mediagoblin], [0.15.0.dev],
	[mediagoblin-devel@gnu.org],
	[mediagoblin],
	[https://mediagoblin.org])
AC_CONFIG_MACRO_DIR([m4])

dnl pkg-config is required prior to generating the configure script
dnl make sure the macros it provides have been successfully replaced
m4_pattern_forbid([^PKG_])

VENV_SUBDIR=.

# Checks for programs.
AC_ARG_WITH([docker],
	    [AS_HELP_STRING([--with-docker],
			    [build a docker image @<:@default=check@:>@])],
			    [use_docker=$withval],
			    [use_docker=check]
			    )
AC_ARG_WITH([npx],
	    [AS_HELP_STRING([--with-npx],
			    [build a npx image @<:@default=check@:>@])],
			    [use_npx=$withval],
			    [use_npx=check]
			    )

AS_IF([test "$use_docker" = check || test "$use_docker" = yes],
      [AC_CHECK_PROGS([DOCKER], [docker], [none])],
      [test "$use_docker" = no], [DOCKER=none],
      [DOCKER=$use_docker]
      )
AS_IF([test "$use_docker" = yes && test "$DOCKER" = none ],
      [AC_MSG_ERROR(docker was not found)]
      )

AS_IF([test "$DOCKER" = none ], [
       AX_PYTHON_DEVEL([3], [>= '3.6'])
       # XXX: Debian: ensurepip comes as a dependency of python3-venv
       AX_PYTHON_MODULE([ensurepip], [1])
       AX_PYTHON_MODULE([venv], [1])

       AC_PROG_AWK

       AS_IF([test "$use_npx" = check],
	     [AC_CHECK_PROGS([NPX], [npx], [none])],
	     [test "$use_npx" = no], [NPX=none],
	     [NPX=$use_npx]
	     )
       AS_IF([test $NPX = none],
	     [AC_MSG_ERROR(npx was not found)]
	     )


       dnl
       dnl Media type plugins [0]
       dnl [0] https://docs.mediagoblin.org/en/master/siteadmin/media-types.html
       dnl

       PKG_PROG_PKG_CONFIG
       AS_IF([test -z "$PKG_CONFIG"],
	     [AC_MSG_WARN([pkg-config not found, some optional dependencies may fail to be correctly detected])]
	     )

       dnl
       dnl mediagoblin.media_types.audio
       dnl
       BUILD_AUDIO=yes
       # XXX: Debian: libgstreamer-plugins-base1.0-dev
       audio_libs="gstreamer-plugins-base-1.0"
       other_audio_dep="gst-libav1.0 gst-plugins-good1.0 gst-python1.0"
       AC_MSG_NOTICE([mediagoblin.media_types.audio: $audio_libs $other_audio_dep])
       PKG_CHECK_MODULES([audio_libs],
			 [$audio_libs],
			 [],
			 [BUILD_AUDIO=no]
			 )
       AS_IF([test $BUILD_AUDIO = yes],
	     [
	      GST_LIBDIR=`$PKG_CONFIG --variable=libdir gstreamer-plugins-base-1.0`
	      LIBS="-L${GST_LIBDIR}/gstreamer-1.0/"
	      AC_CHECK_LIB([gstlibav],
			   [gst_plugin_libav_get_desc],
			   [],
			   [BUILD_AUDIO=no]
			   )
	      # XXX: Debian: gstreamer1.0-plugins-good
	      AC_CHECK_LIB([gstlame],
			   [gst_plugin_lame_get_desc],
			   [],
			   [BUILD_AUDIO=no]
			   )
	     ]
	    )
       AX_PYTHON_MODULE([gi])
       AX_PYTHON_GI([Gst], [1.0])
       AS_IF([test "$HAVE_PYTHON_GI_Gst" = no],
	     [BUILD_AUDIO=no]
	     )
       AS_IF([test $HAVE_PYMOD_GI = no],
	     [BUILD_AUDIO=no]
	     )
       AS_IF([test $BUILD_AUDIO = no],
	     [AC_MSG_WARN(mediagoblin.media_types.audio: some dependencies missing)]
	     )

       dnl
       dnl mediagoblin.media_types.video
       dnl
       AS_IF([test $BUILD_AUDIO = yes],
	     [
	      BUILD_VIDEO=yes
	      # XXX: gstreamer1.0-tools no longer seems needed
	      # Also needs audio libs
	      video_libs="cairo gobject-introspection-1.0"
	      AC_MSG_NOTICE([mediagoblin.media_types.video: $video_libs])
	      PKG_CHECK_MODULES([video_libs],
				[$video_libs],
				[],
				[BUILD_VIDEO=no])
	      # gir1.2-gst-plugins-base-1.0
	      AX_PYTHON_GI([GstVideo], [1.0])
	      AS_IF([test "$HAVE_PYTHON_GI_GstVideo" = no],
		    [BUILD_VIDEO=no]
		    )
	      AS_IF([test $BUILD_VIDEO = no],
		    [AC_MSG_WARN(mediagoblin.media_types.video: some dependencies missing)]
		    )
	      ],
	      [
	       BUILD_VIDEO=no
	       AC_MSG_WARN(mediagoblin.media_types.video: audio dependencies needed)]
	      )

       dnl
       dnl mediagoblin.media_types.raw_image
       dnl
       other_raw_image_libs="libboost-python"
       raw_image_libs="exiv2"
       AC_MSG_NOTICE([mediagoblin.media_types.raw_image: $raw_image_libs])
       BUILD_RAW_IMAGE=yes

       AX_BOOST_PYTHON
       dnl XXX dependent on a variable internal to the macro
       AS_IF([test  "$ac_cv_boost_python" != yes ],
	     [BUILD_RAW_IMAGE=no]
	    )
       PKG_CHECK_MODULES([raw_image_libs],
			 [$raw_image_libs],
			 [],
			 [BUILD_RAW_IMAGE=no]
			 )
       AS_IF([test $BUILD_RAW_IMAGE = no],
	     [AC_MSG_WARN(mediagoblin.media_types.raw_image: some dependencies missing)]
	     )

       dnl
       dnl mediagoblin.media_types.pdf
       dnl
       pdf_cmds="pdfinfo pdftocairo / unoconv (optional, for LibreOffice documents)"
       AC_MSG_NOTICE([mediagoblin.media_types.pdf: $pdf_cmds])
       AC_CHECK_PROG([PDFINFO], [pdfinfo], [yes], [no])
       AC_CHECK_PROG([PDFTOCAIRO], [pdftocairo], [yes], [no])
       AC_CHECK_PROG([UNOCONV], [unoconv], [yes], [no])
       AS_IF([test "$PDFINFO" = no || test "$PDFTOCAIRO" = no && test "$UNOCONV" = no],
	     [
	      BUILD_PDF=no
	      AC_MSG_WARN(mediagoblin.media_types.pdf: some dependencies missing)
	     ],
	     [BUILD_PDF=yes]
	    )

       dnl
       dnl mediagoblin.media_types.stl
       dnl
       stl_cmds="blender"
       AC_MSG_NOTICE([mediagoblin.media_types.stl: $stl_cmds])
       AC_CHECK_PROG([BLENDER], [blender], [yes], [no])
       AS_IF([test $BLENDER = no],
	     [
	      BUILD_STL=no
	      AC_MSG_WARN(mediagoblin.media_types.stl: some dependencies missing)
	     ],
	     [BUILD_STL=yes]
	    )


dnl
dnl Core plugins [0]
dnl [0] https://docs.mediagoblin.org/en/master/#part-2-core-plugin-documentation
dnl
       dnl
       dnl mediagoblin.plugins.ldap
       dnl
       dnl XXX: python-ldap needs libldap_r from OpenLDAP<2.5.2 to build
       dnl https://github.com/python-ldap/python-ldap/issues/432
       other_ldap_dep="ldap"
       ldap_libs="libsasl2"
       AC_MSG_NOTICE([mediagoblin.plugins.ldap: $other_ldap_dep $ldap_libs])
       BUILD_LDAP=yes
       AC_CHECK_LIB([ldap_r],
		    [ldap_open],
		    [],
		    [BUILD_LDAP=no]
		    )
       PKG_CHECK_MODULES([ldap_libs],
			 [$ldap_libs],
			 [],
			 [BUILD_LDAP=no]
			 )
       AS_IF([test $BUILD_LDAP = no],
	     [AC_MSG_WARN(mediagoblin.plugins.ldap: some dependencies missing)]
	     )

        AC_MSG_NOTICE([Plugins with available dependencies:])
cat << EOF
* mediagoblin.media_types.audio:	$BUILD_AUDIO
* mediagoblin.media_types.video:	$BUILD_VIDEO
* mediagoblin.media_types.raw_image:	$BUILD_RAW_IMAGE
* mediagoblin.media_types.pdf:		$BUILD_PDF
* mediagoblin.media_types.stl:		$BUILD_STL
* mediagoblin.plugins.ldap:		$BUILD_LDAP

EOF

       ],
       [
	AC_MSG_NOTICE([preparing a containerised build using ${DOCKER}])
	AC_CONFIG_FILES([
			 Dockerfile.nginx
			 docker-compose.build.yml
			 docker-compose.ecs.yml
			 docker-compose.standalone.yml
			 docker-compose.nginx.yml
			 docker-compose.yml
			 ])
	]
       )

AC_SUBST([BUILD_AUDIO], [$BUILD_AUDIO])
AC_SUBST([BUILD_VIDEO], [$BUILD_VIDEO])
AC_SUBST([BUILD_RAW_IMAGE], [$BUILD_RAW_IMAGE])
AC_SUBST([BUILD_PDF], [$BUILD_PDF])
AC_SUBST([BUILD_STL], [$BUILD_STL])
AC_SUBST([BUILD_LDAP], [$BUILD_LDAP])
AC_SUBST([VENV_SUBDIR], [$VENV_SUBDIR])

AC_CONFIG_FILES([Makefile
		 mediagoblin/_version.py
		 ])
AC_OUTPUT

