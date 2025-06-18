;;; GNU MediaGoblin -- federated, autonomous media hosting
;;; Copyright 2015, 2016 David Thompson <davet@gnu.org>
;;; Copyright 2016 Christopher Allan Webber <cwebber@dustycloud.org>
;;; Copyright 2019, 2020, 2021, 2024 Ben Sturmfels <ben@sturm.com.au>
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.

(define-module (mediagoblin packages)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix git-download)
  #:use-module (guix build-system pyproject)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages check)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages openldap)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-crypto)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages sphinx)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages time)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xml))

;; See README-Guix.md for usage instructions and caveats.

(define-public mediagoblin
  (let ((commit "0bfa4e80da6ff0e4e20a2d7840b3cdc9ed43c127")
        (revision "1"))
    (package
      (name "mediagoblin")
      (version (git-version "0.15.0.dev" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://git.sr.ht/~mediagoblin/mediagoblin")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "07jqzk44if4m14k07rj66dzsi97qyaxxbrk6ky67a70qzv07xjj0"))))
      (build-system pyproject-build-system)
      (arguments
       `(#:phases (modify-phases %standard-phases
                    ;; The mediagoblin/_version.py module is created by
                    ;; ./configure (which we don't run)
                    (add-after 'unpack 'reinstate-version-module
                      (lambda _
                        (copy-file "mediagoblin/_version.py.in" "mediagoblin/_version.py")
                        (substitute* "mediagoblin/_version.py"
                          (("@PACKAGE_VERSION@") (version)))))
                    ;; Override the .gmg-real program name normally from
                    ;; sys.argv[0]. This affects what the usage help
                    ;; message. Could potentially use "env --argv0 gmg" instead?
                    (add-after 'unpack 'fix-program-name
                      (lambda _
                        (substitute* "mediagoblin/gmg_commands/__init__.py"
                          (("ArgumentParser\\(") "ArgumentParser(prog=\"gmg\","))))
                    (add-after 'unpack 'remove-broken-symlinks
                      (lambda _
                        ;; Remove broken symlink for git submodule, since we
                        ;; don't have internet access to fetch it.
                        (delete-file "mediagoblin/static/css/extlib/skeleton.css")
                        ;; Remove broken symlinks caused by having not run `npm install`
                        (delete-file "mediagoblin/static/js/extlib/jquery.js")
                        (delete-file "mediagoblin/static/extlib/videojs-resolution-switcher")
                        (delete-file "mediagoblin/static/extlib/video-js")
                        (delete-file "mediagoblin/static/extlib/leaflet")))
                    ;; Build the language translations
                    (add-after 'build 'build-translations
                      (lambda _
                        (invoke "devtools/compile_translations.sh")))
                    ;; Wrap the executable so it can find GStreamer. Avoids
                    ;; "ValueError: Namespace Gst not available". See
                    ;; beets/clementine.
                    (add-after 'wrap 'wrap-with-gst
                      (lambda* (#:key outputs #:allow-other-keys)
                        (let ((out (assoc-ref outputs "out"))
                              (gst-plugin-path (getenv "GST_PLUGIN_SYSTEM_PATH"))
                              (gi-typelib-path (getenv "GI_TYPELIB_PATH")))
                          (wrap-program (string-append out "/bin/gmg")
                            `("GST_PLUGIN_SYSTEM_PATH" ":" prefix (,gst-plugin-path))
                            `("GI_TYPELIB_PATH" ":" prefix (,gi-typelib-path))))))
                    ;; Use pytest test runner and tweak PYTHONPATH.
                    (replace 'check
                      (lambda* (#:key tests? inputs outputs #:allow-other-keys)
                        (when tests?
                          ;; Put python-py on PYTHONPATH so that it is imported
                          ;; in favour of the shim "py" in pytest. Not sure why
                          ;; this just works on other systems. Could be removed
                          ;; if pytest drops this shim.
                          (let* ((py (assoc-ref inputs "python-py"))
                                 (python (assoc-ref inputs "python"))
                                 (py-path (string-append py "/lib/python" (python-version python) "/site-packages")))
                            (setenv "PYTHONPATH" py-path)
                            (invoke "pytest"))))))))
      (native-inputs (list gobject-introspection
                           python-py  ;Shouldn't have to be specified
                                      ;explicitly, but does - see above
                           python-pytest
                           python-pytest-forked
                           python-pytest-xdist
                           python-sphinx
                           python-webtest
                           python-wheel))
      (inputs (list python-alembic
                    python-babel
                    python-bleach
                    python-celery
                    python-configobj
                    python-dateutil
                    python-exif-read
                    python-feedgenerator
                    python-itsdangerous
                    python-jinja2
                    python-jsonschema
                    python-ldap         ;For LDAP plugin
                    python-markdown
                    python-oauthlib
                    python-openid       ;For OpenID plugin
                    python-pastescript
                    python-pillow
                    python-bcrypt
                    python-pyld
                    python-redis        ;Simplest Celery backend
                    python-requests     ;For batchaddmedia
                    python-soundfile
                    python-sqlalchemy-2
                    python-unidecode
                    python-waitress
                    python-werkzeug
                    python-wtforms
                    python-wtforms-sqlalchemy

                    ;; Audio/video media
                    gst-libav
                    gst-plugins-bad
                    gst-plugins-base
                    gst-plugins-good
                    gst-plugins-ugly
                    gstreamer
                    openh264
                    python-gst          ;For tests to pass
                    python-numpy        ;Audio spectrograms
                    python-pygobject

                    ;; PDF media.
                    poppler))
      (home-page "https://mediagoblin.org/")
      (synopsis "Web application for media publishing")
      (description
       "MediaGoblin is a free software media publishing platform that anyone can
run.  You can think of it as a decentralized alternative to Flickr, YouTube,
SoundCloud, etc.")
      (license (list license:agpl3+ license:cc0)))))

mediagoblin
