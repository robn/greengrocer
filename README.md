# spy

A log collector and search engine

## features

- indexes log lines from files in a trivial JSON format (that rsyslog can produce)
- simple command-line search
- in-built web server for HTTP+JSON searches
- standalone - just Perl and some modules, no separate web server or database required

## quick start

Soon, once I rewrite the docs to match the new code :)

## plans

While spy is still very new, it's fairly close to feature-complete. Future
changes will likely include:

- UI improvements (eg query building, search within results)
- Performance improvements
- Higher-level tooling (eg rolling indexer, auto-rollup at end of day)
- Error recovery
- Documentation

## credits and license

Copyright (c) 2015-2017 Robert Norris. Perl 5 license.

This work was supported by [FastMail](https://www.fastmail.com/).

Loading spinner taken from [SpinKit](http://tobiasahlin.com/spinkit/) by @tobiasahlin. Copyright (c) 2015 Tobias Ahlin (MIT license).

Shout out to Philip O'Toole for [ekanite](https://github.com/ekanite/ekanite), which I would have used had it been ever so slightly further along in its development.

## contributing

Please hack on this and send pull requests :)
