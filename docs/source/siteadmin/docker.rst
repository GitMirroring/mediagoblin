.. _docker-chapter:

=====================
MediaGoblin in Docker
=====================

Since version 0.13.0, Mediagoblin natively supports `Docker
<https://docs.docker.com/>`_. It is possible (and perhaps even preferred) to
build Mediagoblin within a container.

This will create a Docker image suitable to `run on its own
<https://docs.docker.com/engine/reference/run/>`_ as a :ref:`lazyserver
<lazyserver>`, or as part of a `Docker Compose
<https://docs.docker.com/compose/reference/>`_ stack with separate containers
for Paste, Celery, and RabbitMQ. It is even possible to leverage Docker contexts
to start the containers in the cloud, e.g., with `AWS ECS/Fargate
<https://docs.aws.amazon.com/ecs/index.html>`_.

Data persistence, or sharing across containers, is done via volumes, mounted in
`/srv`. In ECS, volumes are mounted from `EFS
<https://docs.aws.amazon.com/efs/index.html>`_.

Build
-----

Unlike a local build, the only dependency required by a Docker build is the
``docker`` tool itself. When present, the ``configure`` script will prefer this
approach (unless ``--without-docker`` is explicitely passed).

The steps to perform a build nonetheless follow the familiar incantation.

.. code-block:: bash

   ./configure && make

This will create a build stage with the necessary build dependencies, such as
``bower`` and ``-dev`` packages, create a final image containing the built package,
and run the tests within a container started from that image.

The name of the image will be ``mediagoblin/mediagoblin:<VERSION>``, e.g.,
``mediagoblin/mediagoblin:0.13.0.dev``.

It is also possible to build the Python Wheel and the docs out of the image,
with

.. code-block:: bash

   make dist
   # and
   make docs

respectively.

When building this way, the dependencies for most plugins (:ref:`media types
<media-types-chapter>` and :ref:`core plugins <core-plugin-section>`) are
included. Two notable exceptions are support of :ref:`Documents <document>` (but
not PDFs), and :ref:`STL files <stl>`.  Their dependencies (``unoconv`` and
``blender``, respectively) were deemed too large to include by default.

While the ``make``-based build is the simplest, it is possible to build custom
containers, with a preferred set of dependencies, directly with ``docker build
.``. Detailing this process is beyond the scope of this chapter. However you can
have a look at the ``Dockerfile`` to see what build arguments (``ARG``,
configurable via ``--build-arg``), are supported.

Run lazyserver in Docker
------------------------

The image is setup to export port 6543, and has a volume for the data available
as ``/srv``. It also has a custom entrypoint which takes care of creating a
default configuration and database if missing, or applying migrations as
necessary after updates.

A single container in charge of both serving and processing content can simply
be started with

.. code-block:: bash

   docker run -p 6543 -v $(pwd)/data:/srv mediagoblin/mediagoblin:<VERSION>

.. note:: See further down in this section to learn how to choose the admin's
   username and password on first run.

The ``-p`` option will make port 6543 of the container available as 6543 on
``localhost``. The ``-v`` option is used to provide a *full path* to a local
directory to mount as a volume at ``/srv`` in the container. This is where all
data and configuration will be written and read from.

If all goes well, you should see the following output on first run.

.. code-block:: bash

   usermod: no changes
   Creating missing configuration file paste.ini ...
   Creating missing configuration file mediagoblin.ini ...
   Configuring plugins ...
   Creating empty database mediagoblin.db ...
   INFO  [alembic.runtime.migration] Context impl SQLiteImpl.
   INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
   INFO  [alembic.runtime.migration] Running upgrade  -> 52bf0ccbedc1, initial revision
   INFO  [alembic.runtime.migration] Running upgrade 52bf0ccbedc1 -> 38feb829c545, Video media type initial migration
   INFO  [alembic.runtime.migration] Running upgrade 52bf0ccbedc1 -> e9212d3a12d3, Audio media type initial migration
   INFO  [alembic.runtime.migration] Running upgrade 52bf0ccbedc1 -> a98c1a320e88, Image media type initial migration
   INFO  [alembic.runtime.migration] Running upgrade 52bf0ccbedc1 -> 101510e3a713, #5382 Removes graveyard items from collections
   INFO  [alembic.runtime.migration] Running upgrade 101510e3a713 -> 8429e33fdf7, Remove the Graveyard objects from CommentNotification objects
   INFO  [alembic.runtime.migration] Running upgrade 8429e33fdf7 -> 4066b9f8b84a, use_comment_link_ids_notifications
   INFO  [alembic.runtime.migration] Running upgrade 4066b9f8b84a -> 3145accb8fe3, remove tombstone comment wrappers
   INFO  [alembic.runtime.migration] Running upgrade 3145accb8fe3 -> 228916769bd2, ensure Report.object_id is nullable
   INFO  [alembic.runtime.migration] Running upgrade 228916769bd2 -> afd3d1da5e29, Subtitle plugin initial migration
   INFO  [alembic.runtime.migration] Running upgrade 228916769bd2 -> cc3651803714, add main transcoding progress column to MediaEntry
   Laying foundations for __main__:
      + Laying foundations for Privilege table
   Cannot link theme... no theme set
   Linked asset directory for plugin "coreplugin_basic_auth":
     /opt/mediagoblin/venv/lib/python3.9/site-packages/mediagoblin/plugins/basic_auth/static
   to:
     /srv/user_dev/plugin_static/coreplugin_basic_auth
   Creating admin user ...
   User created (and email marked as verified).
   The user admin is now an admin.
   Running /opt/mediagoblin/lazyserver.sh -c ./paste.ini --server-name=broadcast ...
   Using paster config: ./paste.ini
   + export CELERY_ALWAYS_EAGER=true
   + pasterUsing paster from $PATH
    serve ./paste.ini --server-name=broadcast --reload
   2022-07-12 12:34:50,497 INFO    [mediagoblin.app] GNU MediaGoblin 0.13.0.dev main server starting
   2022-07-12 12:34:50,921 INFO    [mediagoblin.app] Setting up plugins.
   2022-07-12 12:34:50,921 INFO    [mediagoblin.init.plugins] Importing plugin module: mediagoblin.plugins.geolocation
   2022-07-12 12:34:50,921 INFO    [mediagoblin.init.plugins] Importing plugin module: mediagoblin.plugins.basic_auth
   2022-07-12 12:34:50,922 INFO    [mediagoblin.init.plugins] Importing plugin module: mediagoblin.plugins.processing_info
   2022-07-12 12:34:50,922 INFO    [mediagoblin.init.plugins] Importing plugin module: mediagoblin.media_types.image
   2022-07-12 12:34:50,922 INFO    [mediagoblin.init.plugins] Importing plugin module: mediagoblin.media_types.audio
   2022-07-12 12:34:50,922 INFO    [mediagoblin.init.plugins] Importing plugin module: mediagoblin.media_types.video
   2022-07-12 12:34:51,035 INFO    [mediagoblin.init.celery] Setting celery configuration from object "mediagoblin.init.celery.dummy_settings_module"

It will be terser on subsequent runs, because configuration and databases
already vst, and data migrations aren't necessary.

You can confirm that the container is running happily with the ``docker ps``
command, which will show the running containers, ports and health status (if configured).

.. code-block:: bash

   CONTAINER ID   IMAGE                                          COMMAND                  CREATED          STATUS                    PORTS                                       NAMES
   541710f616d5   mediagoblin/mediagoblin:0.13.0.dev                         "/opt/mediagoblin/en…"   37 seconds ago   Up 36 seconds (healthy)   0.0.0.0:6543->6543/tcp, :::6543->6543/tcp   vibrant_germain

At this point, you should be able to point your browser to http://locahost:6543
and be greeted by the Mediagoblin landing page.

Administrator account
~~~~~~~~~~~~~~~~~~~~~

A default administrator account
is created by the entrypoint script. The login is ``dockeradmin``, and the
password is a very poor one.

You can override both those values on first run, by passing overrides via the
environment.

.. code-block:: bash

   docker run -p 6543:6543 -v $(pwd)/data:/srv \
      -e ADMIN_USER=myadmin -e ADMIN_PASSWORD=anotherbadpassword \
      mediagoblin/mediagoblin:<VERSION>

Alternatively, you can change the password after the fact by using the ``gmg``
tool.

.. code-block:: bash

   docker run -it --rm -v $(pwd)/data:/srv mediagoblin/mediagoblin:<VERSION> \
      gmg changepw admin badpasswordsgalore

You can, of course, use ``gmg`` in this way for any other task you would
generally perform in non-containerised environments.

Spin up a Compose stack
-----------------------

Docker Compose allows to encode more details about how to run a container, such
as volumes, ports and environments variables. This is done via `configuration
file <https://docs.docker.com/compose/compose-file/>`_ instead of the command
line. It also allows spinning up more that one container at a time, and setting
up the necessary network environment so they can communicate with each other.

Multiple configurations files can be used at the same time, to selectively
configure or various aspect of the desired stack. Mediagoblin takes this
approach, in providing a basic ``docker-compose.yml``, which contains shared
options, and a number of additional overlays allowing to run a non-lazy
deployment locally, or a similar deployment in AWS ECS.

.. note:: Historically, ``docker-compose`` was a command separate to ``docker``
 itself, but functionality has now been merged and extended. This guide
 therefore uses the ``docker compose`` subcommand.

Lazyserver
~~~~~~~~~~

Prior to delving into mult-container stacks, you can have a look at the
standalone ``docker-compose.lazyserver.yml`` which does very little more than
the ``docker`` commands in the previous section.  There are however two
noteworthy differences.

.. literalinclude:: ../../../docker-compose.lazyserver.yml
   :language: yaml

First, in the ``volumes`` section, a named docker volume, ``mediagoblin-data``
is created for ``/srv``. It will be reused every time a stack is brought up.
This allows for some amount of data persistence. It is however not as
conveniently reachable as a file-system bind mount, as shown before, is.

Second, it uses an ``env_file``, which allows to conveniently pass a number of
environment variables to the container. See the next section to learn about
variables used by the entrypoint script (including admin username and password)
are set.

These changes will be carried over through the next few sections.

``docker compose`` uses file ``docker-compose.yml`` by default. To use the
lazyserver variation, the ``-f`` option can be use.

.. code-block:: bash

   docker compose -f docker-compose.lazyserver.yml up

.. note:: By default, docker will keep hold of the terminal, and output logs from the application. To regain use of the terminal, you can add the ``-d`` flag at the end of this command. To see the logs, you can then use ``docker compose logs -f``.

As before, this will make the Mediagoblin instance available at
http://localhost:6543/. You can log in as the admin, and upload a file before moving on to the next section.

Again, the admin account is automatically created, but based on the
``ADMIN_USER`` and ``ADMIN_PASSWORD`` present in the ``docker-compose.env``
file (see next section).

You can shut the container down with

.. code-block:: bash

   docker compose -f docker-compose.lazyserver.yml down

Configuration via environment variables
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is the recommended approach when creating a new stack, as it can be
used in environment where using ``docker [compose] run`` may not be practical
to change the password with ``gmg``.

.. literalinclude:: ../../../docker-compose.env
   :language: bash


Multi-container stack
~~~~~~~~~~~~~~~~~~~~~

The previous section was a light introduction into ``docker-compose.yml``
files, but didn't achieve much. We can now move on to defining more than one
service in the stack: separate Paste and Celery containers, with a side of
RabbitMQ and Nginx.

The basic ``docker-compose.yml`` file does just that.

.. literalinclude:: ../../../docker-compose.yml
   :language: yaml

It is fairly similar to the lazyserver setup, except it defines all three
services. Both ``paste`` and ``celery`` are essentially the same, except for
the ``command`` that is executed. Some additional environment variables are set
in the ``environment`` section, most notably where to find RabbitMQ. The
``healthcheck`` of the Celery container is also adjusted to remain useful.

One last service is started, based on the official RabbitMQ images, to support
communication between both containers, and some start-up order rules are
defined via the ``depends_on`` sections.

As this configuration is in the default ``docker-compose.yml`` file, starting the stack up is fairly straight forward.

.. code-block:: bash

   docker compose up

As before, this stack uses the ``mediagoblin-data`` named volume, which is
mounted in both Paste and Celery containers. If you started a fresh lazyserver
before, and uploaded some test data, you should still be able to access it now.

Working with named volumes
~~~~~~~~~~~~~~~~~~~~~~~~~~

So far, data has been stored in the ``mediagoblin-data`` named volume. You can
list all existing named volumes with

.. code-block:: bash

   docker volume ls

If all the containers using them are down, you can also delete them. A quirk is
that even though Docker Compose sees it as ``mediagoblin-data``, it prefixes
its name with that of the stack getting created. By default this is simply the
name of the directory with the compose file is. In this case, the full volume
name will be ``mediagoblin_mediagoblin-data``.

.. code-block:: bash

   docker volume rm mediagoblin_mediagoblin-data

Data persistence with a local mount
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

XXX: TODO: merge with above

Rather than persisting data in a docker volume, it is possible mount a local
directory in at ``/srv`` in the container. On a local Docker host, this makes it easier to inspect, modify and backup data.

This can be easily done by changing the ``volumes`` configuration of the ``services``. To make things simpler, an override file doing just that is provided, ``docker-compose.local.yml``.

.. literalinclude:: ../../../docker-compose.local.yml
   :language: yaml

It mounts the local ``./data`` directory into ``/srv`` in both containers. As
an added bonus, it also sets a ``restart`` policy that services should always
be restarted if they die.

It needs to be used `in addition to` the basic ``docker-compose.yml``. This can be done as follows.

.. code-block:: bash

   mkdir data
   docker compose -f docker-compose.yml -f docker-compose.local.yml up

Starting with an empty ``data`` directory, the container will create the
configuration and the database on first run. You can confirm it with ``ls
data`` outside of the container.

.. code-block:: bash

   mediagoblin  mediagoblin.db  mediagoblin.ini  paste.ini  user_dev

Nginx
~~~~~

.. code-block:: bash

   docker build -f Dockerfile.nginx . -t mediagoblin/nginx:<VERSION>

.. code-block:: bash

   docker-compose -f docker-compose.yml -f docker-compose.nginx.yml up

.. note:: As the nginx container is added via an override, the ``paste``
   container continues to expose it own port to the rest of the system.

Run Mediagoblin in the cloud
----------------------------

ecs

.. code-block:: bash

   docker compose -f docker-compose.yml -f docker-compose.ecs.yml up

Configuring plugins
~~~~~~~~~~~~~~~~~~~

Development
-----------

.. code-block:: bash

   docker run -p 6543:6543 \
      -v $(pwd):/opt/mediagoblin \
      -v $(pwd)/data:/srv \
      mediagoblin:<VERSION>
