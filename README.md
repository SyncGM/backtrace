
Backtrace v1.0 by Solistra
=============================================================================
Summary
-----------------------------------------------------------------------------
  This script provides the missing full error backtrace for RGSS3 as well as
a number of features related to exception handling for debugging. Normally,
the error message raised when an exception is encountered provides only the
exception information without providing the backtrace; this script rectifies
that by displaying the backtrace within the RGSS Console when applicable,
potentially logging the backtrace to a file, and allowing developers to play
games with critical bugs without causing the entire engine to crash by
optionally swallowing all exceptions.

License
-----------------------------------------------------------------------------
  This script is made available under the terms of the MIT Expat license.
View [this page](http://sesvxace.wordpress.com/license/) for more detailed
information.

Installation
-----------------------------------------------------------------------------
  Place this script below Materials, but above Main. Place this script below
any other script which aliases `SceneManager.run` for maximum compatibility.

