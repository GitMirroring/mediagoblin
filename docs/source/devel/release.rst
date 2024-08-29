=================
Release Checklist
=================

- update docs/source/siteadmin/relnotes.txt
- update docs/source/siteadmin/upgrading.txt
- update configure.ac version to remove ".dev" suffix
- write a blog post
- test the upgrade process
- build the docs and check they look good
- git tag v0.11.0 --signed --message
- push tags
- log in and rebuild master and new version docs on readthedocs.org
- push docker containers
  - docker login -u mediagoblin
  - docker push mediagoblin/mediagoblin:VERSION
  - docker push mediagoblin/nginx:VERSION
- merge into stable branch
- post to mediagoblin-devel
- post to info-gnu@gnu.org
- post to mastodon and twitter
- email personal contacts
- update configure.ac version again to add ".dev" suffix and increment version

Do we even need a stable branch? I'm not entirely happy with the upgrade
instructions "git fetch && git checkout -q v0.11.0 && git submodule update". Why
have a stable branch if you're asking them to checkout a particular tag anyway?

What to do if you've pushed a tag and the docs need updating?
