# MediaGoblin OS packaging for GNU Guix #

This repository contains a Guix channel for the work-in-progress MediaGoblin
package/service. Once this has been sufficiently developed, we hope to merge it
into upstream Guix.

Overall progress and discussion is being tracked in the bug "Package GNU
MediaGoblin as a Guix service" on Guix's bug tracker:
https://debbugs.gnu.org/cgi/bugreport.cgi?bug=47260

**Status**: It works! MediaGoblin can be installed as a Guix package with no
external dependencies or Python virtualenvs. After some slightly awkward initial
configuration the web interface runs successfully based on an SQLite
database. Images, audio and video can be uploaded and viewed successfully. Video
plays via the stock browser player but doesn't allow selection of video
quality. Some minor features like video bitrate switching are not available due
to missing jQuery and Video.js.

**Getting started**: To get started quickly, follow the instructions in "Install
via load-path", followed by "Run MediaGoblin".

**Jobs to do**:

* Vendor-in skeleton.css as being a git submodule, it's not available in the
  built package. We're currently only using `skeleton.css` (~250 lines) and not
  the included `base.css` or `layout.css`.

* Add a `gmg init` command to create a default `mediagoblin.ini` and `paste.ini`
  in the current directory. Should remind you to run `gmg dbupdate`.

* Add a console/or web UI warning like, "This is an initial release of the
  MediaGoblin's OS packages with significant known issues. Please bear with us
  and report any other issues to ...".

* Publish MediaGoblin 0.14.0 so we have a release with all our updated
  dependencies.

* I'm seeing the video transcoding task hanging just before 100%. May or may not
  be Redis-related, as the [Celery 5.4.0 release
  notes](https://docs.celeryq.dev/en/v5.4.0/changelog.html#version-5-4-0)
  mention issues with Redis. Haven't ever seen this outside of Guix though. More
  investigation required.

* We don't have NPM/Bower available to install jQuery and others. We've mostly
  tweaked things so that MediaGoblin is usable without it, but further work is
  needed. A start would be to rewrite MediaGoblin's JavaScript code not to use
  jQuery. We could bundle some of the third-party JS into MediaGoblin, but we
  could possibly also get a long way by improving no-third-party-JS experience
  too. Minimising the third-party JS will simplify packaging for other operating
  systems.

* Package MediaGoblin as a Guix service. Possibly not necessary for an initial
  release of the upstream Guix package though - the audience for server-only
  Guix services is still fairly small. More people may just use Guix to install
  MediaGoblin on Debian, or build a .deb, .rpm or Docker image.


## Install via channels.scm (for end-use) ##

First install Guix from https://guix.gnu.org.

Add this MediaGoblin channel to your Guix channels configuration in
`~/.config/guix/channels.scm`:

``` scheme
(cons
  (channel
    (name 'mediagoblin)
    (url "https://git.sr.ht/~mediagoblin/mediagoblin")
    (introduction
      (make-channel-introduction
      "d4b2f5b67c6862346e0f91b5e964d5b07878046d"
      (openpgp-fingerprint
        "3E7F36E73BDD6A7106F92021023C05E2C9C068F0"))))
  %default-channels)
  ```
With the channel configured, it can be used as follows:

    guix pull
    guix install mediagoblin

See "Run MediaGoblin" below.


## Set up a MediaGoblin hacking environment (for MediaGoblin development) ##

    guix environment -L ../mediagoblin mediagoblin
    # See the "Run MediaGoblin" section below for initial configuration
    CELERY_ALWAYS_EAGER=true python3 -m mediagoblin.gmg_commands.__init__ serve paste.ini

Or with a separate Celery task queue (see more details below):

    python3 -m mediagoblin.gmg_commands.__init__ serve paste.ini
    python3 -m mediagoblin.gmg_commands.__init__ celery
    python3 -m celery --broker='redis://' amqp queue.purge default


## Build MediaGoblin (for Guix testing/development) ##

To build MediaGoblin:

    git clone https://git.sr.ht/~mediagoblin/mediagoblin
    cd mediagoblin
    guix build -L . mediagoblin

To build with modified source:

    guix build -L . mediagoblin --with-source=mediagoblin=[SOURCE DIRECTORY]

To build without running tests:

    guix build -L . mediagoblin --without-tests=mediagoblin


## Install via load-path (for Guix testing/development) ##

For flexibility during testing and development, install using Guix's load-path:

    git clone https://git.sr.ht/~mediagoblin/mediagoblin
    cd mediagoblin
    guix shell -L . mediagoblin  # For a temporary shell
    guix install -L . mediagoblin  # To install in your profile


## Run MediaGoblin ##

After installing using either installation method above, create a new directory
for your MediaGoblin configuration, database and media storage:

    mkdir mediagoblin.example.org
    cd mediagoblin.example.org

**Note**: The following configuration setup is a bit of a workaround for now.
There needs to be a better way to obtain default configuration and to reference
the include static files.

Download MediaGoblin's default configuration file and enable audio and video
support:

    curl https://git.savannah.gnu.org/cgit/mediagoblin.git/plain/mediagoblin.example.ini > mediagoblin.ini
    echo "[[mediagoblin.media_types.audio]]" >> mediagoblin.ini
    echo "[[mediagoblin.media_types.video]]" >> mediagoblin.ini

Download MediaGoblin's default Paste Deploy configuration file and update the
`/mgoblin_static` path to refer to your installed MediaGoblin static files:

    curl https://git.savannah.gnu.org/cgit/mediagoblin.git/plain/paste.ini > paste.ini

Create an sqlite3 database and add a user:

    gmg dbupdate
    gmg adduser --username admin --password a --email admin@example.com

Upload an image, audio and video via CLI:

    gmg addmedia admin image.jpg
    gmg addmedia admin audio.wav
    gmg addmedia admin video.mp4

Start the web interface with foreground media processing:

    CELERY_ALWAYS_EAGER=true gmg serve paste.ini

**Note**: The web interface is currently missing some static files:

 - `jquery.js`: normally installed with `bower`


## Background media processing ##

To enable background media processing, install a Redis system service (see Guix
documentation), then modify mediagoblin.ini to include:

    [celery]
    broker_url = "redis://"

Now in a separate terminal run Celery:

    gmg celery

Stop your existing web interface instance and re-run with
`CELERY_ALWAYS_EAGER` omitted:

    gmg serve paste.ini


## Building a Debian package ##

To build a Debian package:

    guix pack -f deb -C xz -L . -S /usr/bin/gmg=bin/gmg mediagoblin

For other options including RPM and Docker, see
https://guix.gnu.org/manual/en/html_node/Invoking-guix-pack.html#Invoking-guix-pack.
