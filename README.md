
Backtrace v1.4 by Solistra
=============================================================================

Summary
-----------------------------------------------------------------------------
  This script provides the missing full error backtrace for RGSS3 as well as
a number of features related to exception handling for debugging.

  Normally, the error message given when an exception is encountered provides
only the exception information without providing the backtrace; this script
rectifies that by displaying the backtrace within the RGSS Console when
applicable, potentially logging the backtrace to a file, and allowing script
developers to test games with critical bugs without causing the entire engine
to crash by optionally swallowing all exceptions.

License
-----------------------------------------------------------------------------
  This script is made available under the terms of the MIT Expat license.
View [this page](http://sesvxace.wordpress.com/license/) for more detailed
information.

Installation
-----------------------------------------------------------------------------
  Place this script anywhere below the SES Core (v2.0 or higher) script (if
you are using it) or the Materials header, but above Main. This script does
not require the SES Core, but it is highly recommended.

  Place this script below any script which aliases or overwrites the 
`Game_Interpreter#update` method for maximum compatibility.

