=================
Release Checklist
=================

- update AUTHORS file
- update docs/source/siteadmin/relnotes.txt
- update docs/source/siteadmin/upgrading.txt
- confirm CI builds are passing
- a developer should test the upgrade instructions on their own system
- once in a while a developer should install from scratch to ensure docs are appropriate
.. - do a ./devtools/update_translations.sh and make sure you have the latest translations.
- update configure.ac version to remove ".dev" suffix
- write a blog post
- test the upgrade process
- build the docs and check they look good
- git tag vX.Y.Z --signed --message
- push tags
- log in and rebuild master and new version docs on readthedocs.org
- push docker containers

  - docker login
  - docker push mediagoblin/mediagoblin:VERSION
  - docker push mediagoblin/nginx:VERSION

- merge into stable branch and push
- build the tarfile. `./devtools/maketarball.sh -r vX.Y.Z`
- push the tarball to the website: add tarball to `content/download/` directory in mediagoblin-website repository and then push the site live
- build PyPI release and upload
- post to mediagoblin-devel
- post to info-gnu@gnu.org
- post to mastodon and twitter
- email personal contacts
- update configure.ac version again to add ".dev" suffix and increment version
.. - file an issue at https://github.com/jparyani/mediagoblin/issues for the new version

Do we even need a stable branch? I'm not entirely happy with the upgrade
instructions "git fetch && git checkout -q v0.11.0 && git submodule update". Why
have a stable branch if you're asking them to checkout a particular tag anyway?

What to do if you've pushed a tag and the docs need updating?
