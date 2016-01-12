# greengrocer

A log collector and search engine

## features

- accepts messages from the network in a trivial JSON format (that rsyslog can produce)
- simple command-line search
- in-built web server for HTTP+JSON searches
- standalone - just Perl and some modules, no separate web server or database required

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
[greengrocer] 2016-01-11T16:33:20 commit interval is 10, rolling every 24 hours
[greengrocer] 2016-01-11T16:33:20 listening on 0.0.0.0:5514, receive buffer is 425984 bytes
[greengrocer] 2016-01-11T16:33:50 indexed 8 lines [add 0.004 (0.000543) commit 0.002 (0.000242)]
[greengrocer] 2016-01-11T16:35:10 indexed 3 lines [add 0.006 (0.001923) commit 0.008 (0.002777)]
[greengrocer] 2016-01-11T16:36:50 indexed 8 lines [add 0.002 (0.000228) commit 0.001 (0.000181)]
...
```

And now you can run searches:

```
$ ./greengrocer -d /tmp/greengrocer search robntest
2015-12-22T00:05:46.534634-05:00 imap30 sloti30t15/imap[4101108]: login: frontend1.nyi.internal [10.202.2.160] robntest plaintext User logged in SESSIONID=<sloti30t15-4101108-1450760746-1-6931901653674999381>
2015-12-22T00:05:43.153712-05:00 imap30 sloti30t15/imap[4101108]: login: frontend1.nyi.internal [10.202.2.160] robntest plaintext User logged in SESSIONID=<sloti30t15-4101108-1450760743-1-8621255614016944209>
```

Or using the search server:

```
$ cpanm Starman Plack Plack::Middleware::Redirect Atto
$ ./greengrocer -d /tmp/greengrocer web
[greengrocer] 2016-01-12T07:30:48 0.0.0.0:5515 listening
```

```
$ curl -s http://127.0.0.1:5515/search?query=robntest
{
   "count" : 2,
   "matches" : [
      {
         "timestamp" : "2016-01-11T15:03:59.020292-05:00",
         "host" : "imap30",
         "message" : " login: frontend2.nyi.internal [10.202.2.161] robntest plaintext User logged in SESSIONID=<sloti30t15-932691-1452542639-1-17409801321091060504>",
         "pid" : "932691",
         "program" : "sloti30t15/imap"
      },
      {
         "program" : "sloti30t15/imap",
         "host" : "imap30",
         "message" : " login: frontend2.nyi.internal [10.202.2.161] robntest plaintext User logged in SESSIONID=<sloti30t15-932691-1452542642-1-10809176855088304008>",
         "pid" : "932691",
         "timestamp" : "2016-01-11T15:04:02.062097-05:00"
      }
   ]
}
```

The search server also presents a nice little UI; point your browser to `/ui/`.

Run `greengrocer` without options to find out about other knobs you can twiddle.

## plans

This is still under development. Current plans include:

- optimise indexes at end-of-day
- allow indexes in multiple locations
- move old indexes to different locations (eg slow storage)

## credits and license

Copyright (c) 2015-2016 Robert Norris. MIT license. See LICENSE.

Shout out to Philip O'Toole for [ekanite](https://github.com/ekanite/ekanite), which I would have used had it been ever so slightly further along in its development.

## contributing

Please hack on this and send pull requests :)
