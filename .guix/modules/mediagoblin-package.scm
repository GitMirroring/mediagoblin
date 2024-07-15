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

(define-module (mediagoblin-package)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix git-download)
  #:use-module (guix build-system pyproject)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages check)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages openldap)
  #:use-module (gnu packages pdf)
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
  (let ((commit "d2eb89e786d578663c15c5ac302d4b0d9d40c29f")
        (revision "3"))
    (package
      (name "mediagoblin")
      (version (git-version "0.14.0.dev" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://git.sr.ht/~mediagoblin/mediagoblin")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1cbq3r79gyklf55hxah05dxmp7i8c6aw45z729niw36dvvjg500p"))))
      (build-system pyproject-build-system)
      (arguments
       `(#:phases (modify-phases %standard-phases
                    ;; The mediagoblin/_version.py module is created by
                    ;; ./configure (which we don't run)
                    (add-after 'unpack 'reinstate-version-module
                      (lambda _
                        (copy-file "mediagoblin/_version.py.in" "mediagoblin/_version.py")
                        (substitute* "mediagoblin/_version.py"
                          (("@PACKAGE_VERSION@") "0.14.0.dev1"))))
                    ;; Override the .gmg-real program name from sys.argv[0]
                    (add-after 'unpack 'hide-wrapping
                      (lambda _
                        (substitute* "mediagoblin/gmg_commands/__init__.py"
                          (("ArgumentParser\\(") "ArgumentParser(prog=\"gmg\","))))
                    (add-after 'unpack 'remove-broken-symlinks
                      (lambda _
                        ;; Remove broken symlink for git submodule
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
                    ;; Use pytest test runner
                    (replace 'check
                      (lambda* (#:key tests? #:allow-other-keys)
                        (when tests?
                          (invoke "pytest" "mediagoblin/tests" "-rs" "--forked")))))))
      (native-inputs (list gobject-introspection
                           python-pytest
                           python-pytest-forked
                           python-pytest-xdist
                           python-sphinx
                           python-webtest))
      (inputs (list python-alembic
                    python-babel
                    python-celery
                    python-configobj
                    python-dateutil
                    python-exif-read
                    python-feedgenerator
                    python-itsdangerous
                    python-jinja2
                    python-jsonschema
                    python-ldap ;For LDAP plugin
                    python-lxml
                    python-markdown
                    python-oauthlib
                    python-openid ;For OpenID plugin
                    python-pastescript
                    python-pillow
                    python-bcrypt
                    python-pyld
                    python-redis ;Simplest Celery backend
                    python-requests ;For batchaddmedia
                    python-soundfile
                    python-sqlalchemy
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
                    python-gst ;For tests to pass
                    python-numpy ;Audio spectrograms
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
