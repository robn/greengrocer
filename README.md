# greengrocer

A log collector and search engine

## features

- accepts messages from the network in a trivial JSON format (that rsyslog can produce)
- simple command-line search
- standalone - just Perl and some modules, no web server or database required

## quick start

```
$ cpanm Lucy Path::Tiny AnyEvent AnyEvent::Handle::UDP Date::Format Date::Parse JSON::XS
$ ./greengrocer -d /tmp/greengrocer agent
```

Then in your `rsyslog.conf`:

```
$template greengrocer,"{%msg:::jsonf:message%,%HOSTNAME:::jsonf:host%,%timereported:::date-rfc3339,jsonf:timestamp%,%syslogtag:::jsonf:syslogtag%}"
*.* @127.0.0.1:5514;greengrocer
```

Back where you ran the agent, you should start to see it receiving log lines:

```
$ ./greengrocer -d /tmp/greengrocer agent
[greengrocer] 2015-12-22T00:03:34 0.0.0.0:5514 listening
[greengrocer] 2015-12-22T00:03:43 127.0.0.1:43195 connect
[greengrocer] 2015-12-22T00:03:44 indexed 51 lines
[greengrocer] 2015-12-22T00:03:45 indexed 130 lines
...
```

And now you can run searches:

```
$ ./greengrocer -d /tmp/greengrocer search robntest
2015-12-22T00:05:46.534634-05:00 imap30 sloti30t15/imap[4101108]: login: frontend1.nyi.internal [10.202.2.160] robntest plaintext User logged in SESSIONID=<sloti30t15-4101108-1450760746-1-6931901653674999381>
2015-12-22T00:05:43.153712-05:00 imap30 sloti30t15/imap[4101108]: login: frontend1.nyi.internal [10.202.2.160] robntest plaintext User logged in SESSIONID=<sloti30t15-4101108-1450760743-1-8621255614016944209>
```

Run `greengrocer` without options to find out about other knobs you can twiddle.

## plans

This is a super-early work-in-progress (as I write this, it's existed less than a day). Current plans are:

- optimise indexes at end-of-day
- allow indexes in multiple locations
- move old indexes to different locations (eg slow storage)
- simple HTTP+JSON search interface

## credits and license

Copyright (c) 2015 Robert Norris. MIT license. See LICENSE.

Shout out to Philip O'Toole for [ekanite](https://github.com/ekanite/ekanite), which I would have used had it been ever so slightly further along in its development.

## contributing

Please hack on this and send pull requests :)
