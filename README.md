# GNU MediaGoblin

<img src="https://mediagoblin.org/images/home_goblin.png" alt="">

MediaGoblin is a free software media publishing platform that anyone can run.
You can think of it as a decentralized alternative to Flickr, YouTube,
SoundCloud. It's also:

* The perfect tool to show and share your media!
* Building tools to empower the world through decentralization!
* Built for extensibility. Multiple media types, including video support!
* Part of the GNU project and devoted to user freedom.
* Powered by a community of people like you.

MediaGoblin is a self-hosted web application that you install on a server you or
your organisation controls. See our [Deploying
MediaGoblin](https://docs.mediagoblin.org/en/master/siteadmin/deploying.html)
for instructions.

Please see our [join us](https://mediagoblin.org/pages/join.html) page us and
get involved!

* [website](https://mediagoblin.org)
* [documentation](https://docs.mediagoblin.org)
* [bug tracker](https://todo.sr.ht/~mediagoblin/mediagoblin)
* [bug tracker (legacy)](https://issues.mediagoblin.org)
* [CI](https://builds.sr.ht/~mediagoblin/mediagoblin)


## Contributing

Sending patches to MediaGoblin is done [by
email](https://lists.gnu.org/mailman/listinfo/mediagoblin-devel), this is simple
and built-in to Git.

Set up your system once by following the steps "Installation and Configuration"
of [git-send-email.io](https://git-send-email.io/).

Then, run once in this repository:
```shell
git config sendemail.to "mediagoblin-devel@gnu.org"
```

Then, to send a patch, make your commit, then run:
```shell
git send-email --base=HEAD~1 --annotate -1 -v1
```

It should then appear on [the mailing list
archive](https://lists.gnu.org/archive/html/mediagoblin-devel/).
