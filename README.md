Date::Performance
=================

This package adds some semblance of performance to Ruby 1.8's core Date class 
using a combination of different techniques:

1. Implements various core *Date* methods in C. This is nowhere near a
   complete rewrite of all *Date* features but many of the hot spots have
   been replaced with machine code.
 
2. Provide alternate implementations of `strftime` and `strptime` in C.  The stock
   date formatting and parsing methods are extremely slow compared to their
   libc counterparts. *Date#sys_strftime* and *Date::sys_strptime* are light
   facades on top of the system's `strftime(2)` and `strptime(2)`. The system 
   methods run 10x and 50x (yes, _fifty-ecks_) faster than their Ruby based counterparts, 
   respectively.  Unfortunately, `strftime(2)` and `strptime(2)` implementations vary from
   system to system and have various limitations not found in the core Date
   implementation so can not safely be used as replacements for the core methods.

3. Memoization. The *Date::Memoize* module can be used to speed certain
   types of repetitive date processing significantly. This file must be 
   required separately.

Synopsis
--------

This package is mostly transparent after an initial require:

    require 'date/performance'
    Date.new 1912, 6, 23
    # Wow! That was fast!

*Date::Performance* is not used directly but automatically replaces core *Date*
methods when required.

In addition to the C extension, the *Date::Memoization* module can be used to
speed things up even further in some cases by making a trade off between space 
and time:

    require 'date/memoize'
    Date.new 1912, 6, 23
    Date.parse '1912-06-23'

Requiring the file automatically replaces *Date::new* / *Date::civil*, *Date::parse*, 
and *Date::jd* methods with memoized versions.

Installation / Hacking
----------------------

This package has been tested on the following platforms:

  * FreeBSD 5.4 (x86) and 6.1 (AMD64)
  * Linux / Fedora Core 6 (x86)
  * MacOS X (Intel)

The easiest way to install the package is to use RubyGems:

    $ gem install date-performance

A git repository is also available:

    $ git clone git://github.com/rtomayko/date-performance.git

Background
----------

The *Date* class is often the cause of poor performance in Ruby programs. A frequent
suggestion is to use the *Time* class, which is much faster, but that solution has 
correctness problems in a wide range of data typing cases. It is often the case that 
you want separate *Date*, *Time*, and *DateTime* types.

There are a couple of reasons why *Date* runs slowly when compared with
*Time*. The common assumption is that this is mostly due to *Time* being
written in C and *Date* being written in Ruby. While that clearly has an
impact, I would argue that the reason *Date* is slow is because it's not
designed to be fast. The code opts for readability over performance in almost
every case. _This is a feature_.

Have you read the *date.rb* documentation [1]? The implementation is pretty
hard core; it can handle a lot of weird cases that *Time* [2] does not and
would appear to be a correct implementation of date handling, which has the
usual side-effect of being slow.

The *Date* implementation uses a single Astronomical Julian Day (AJD) number
to represent dates internally. In fact, *Date#initialize* takes a
single `ajd` argument, which means that all date forms that are commonly used 
(UNIX timestamp, Civil, etc.) must be converted to an AJD before we can even
instantiate the thing. 

The real performance hit seems to come from the various rational number
operations performed on the way from a civil, ordinal, and julian date to 
an AJD.

When I began writing *Date::Performance*, I was getting pretty big (3x - 4x)
performance boosts in many places simply by optimizing the Ruby code a bit.
These boosts came at the expense of readability, however, and so the decision
was made to go for _maximum unreadability_ and implement the boosts in C.

There's a nice balance here: the Ruby implementation reads like a spec,
while the C version implements it for quickness.

Memoization
-----------

In addition to the C extension, this package includes a separate *Date::Memoize*
module that can further speed up date processing in situations where the range
of dates being manipulated is fairly dense and the same dates are being
created repeatedly. Working with databases and flat files are two examples
where memoization may help significantly.

The *Date::Memoize* module replaces various Date constructor methods (`new`,
`civil`, and `parse`) with memoized[http://en.wikipedia.org/wiki/Memoization] 
versions (see *Date::Memoization* for details). The best way to determine 
whether memoization is right for you is to add it to your project and see 
what happens.

License
-------

MIT. See the COPYING file included in the distribution for more 
information.

See Also
--------

 * [1] Ruby *Date* Implementation Notes and Documentation:
   http://www.ruby-doc.org/docs/rdoc/1.9/files/_/lib/date_rb.html

 * [2] Ruby *Time* documentation 
   http://www.ruby-doc.org/docs/rdoc/1.9/classes/Time.html
