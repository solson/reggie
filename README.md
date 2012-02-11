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

Prepend 'n' exclamation marks before the "s/" to make reggie replace the 'n'th
last line you said (ignores the lines of others). 'n' is limited to the
`@max_bangs` instance variable in reggie.rb.

If you don't use any `!`s and reggie cannot match your regex to the previous
line, it will try to match against your 'n' previous lines from most recent to
earliest.

Reggie handles /me (ACTION) lines correctly.

Ruby Regex
----------
A decent reference for Ruby regex can be found
[here](http://is.gd/rubyregexp).

Requirements
------------
Reggie requires the 'cinch' gem.

