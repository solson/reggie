Reggie
======
Reggie is a little IRC bot that watches for perl-style `s/match/replace/` in
chat and performs the actual regex replace (using Ruby's regex) on the
previous line and prints the result.

Usage
-----
``` irc
<scott> This is a tset.
<scott> s/tset/test/
<reggie> <scott> This is a test.
```

To replace the last line *you* said, ignoring other users' lines, prepend an
exclamation mark to your replacement line.

``` irc
<scott> This is a tset.
<some_guy> This is another tset.
<scott> s/tset/test/
<reggie> <some_guy> This is another test.
<scott> !s/tset/test/
<reggie> <scott> This is a test.
```

You can use multiple exclamation marks to refer to your even earlier lines.
You can only use as many exclamation marks as the `@max_bangs` instance
variable in `reggie.rb`, which is 3 by default.

If you don't use any exclamation marks and reggie cannot match your regex to
the previous line, it will try to match against your previous lines from most
recent to earliest as if you had attempted `!s`, `!!s`, ..., until you got a
match. This is also limited by the `@max_bangs` instance variable.

``` irc
<scott> This is a tset.
<some_guy> Blah blah blah!
<scott> s/tset/test/
<reggie> <scott> This is a test.
```

Reggie handles `/me` (`ACTION`) lines correctly.

``` irc
* scott is tseting.
<scott> s/tset/test/
<reggie> * scott is testing.
```

Ruby Regex
----------
A decent reference for Ruby regex can be found
[here](http://is.gd/rubyregexp).

Requirements
------------
Reggie requires the [cinch](https://github.com/cinchrb/cinch) gem.

