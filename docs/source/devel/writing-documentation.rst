=====================
Writing documentation
=====================

Overview
========

We use `Sphinx`_ to build the user manual. It's located in the docs/ directory
of the repository.

.. _Sphinx: http://sphinx.pocoo.org/


Conventions
===========

The manual has three parts to it that cater to three different target audiences:


Site Administrator's Guide
--------------------------

Written for people who want to install MediaGoblin on their server and maintain
it. This is an outward-facing part of our project, so the tone needs to be
upbeat, exciting at times, and inclusive. The site administrators are becoming
part of our community when they choose to use MediaGoblin. The documentation
tone should reflect that. This isn't just a piece of software, it's a
revolution! Having said that, the tone shouldn't adversely affect clarity--the
documentation needs to be clear.


Core Plugin Documentation
-------------------------

This documentation is located in README files in the core plugin directories. It
needs to be clear, easy to read, easy to follow sets of instructions for
installation, upgrading, configuring and using the respective plugins.


Plugin Writer's Guide
---------------------

Written for people who are writing plugins. This documentation can be on the
technical side of things. Like the Site Administrator's Guide, it's an
outward-facing part of our project and so it should be upbeat and inclusive. It
is technical documentation, though, so lists, definition lists, and other
technical shorthand is important. Working examples are important.


Heading hierarchy
=================

We use the following heading hierarchy::

   ================
    Document title
   ================
   
   Heading 1
   =========
   
   Heading 2
   ---------
   
   Heading 3
   ^^^^^^^^^


Building output
===============

To build HTML, do::

   cd docs/
   make html

The HTML version of the docs will then be in docs/_build/html/.

To build texinfo, do::

   cd docs/
   make info

The Texinfo version of the docs will then be in docs/_build/texinfo/.

To test, open up Emacs and do C-u C-h i and then select the .info file. Read through it, make sure the images are correct and that there aren't weird things. Note that you need to use a graphical Emacs and not a command shell Emacs. 
