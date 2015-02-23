=begin
Copyright 2012-2015, Alexander C. Schreyer
All Rights Reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/sketchfab-uploader-plugin-for-sketchup/

Name :          Sketchfab Uploader

Version:        2.1
Date :          3/17/2014

Description :   This plugin uploads the currently open model to Sketchfab.com

Usage :         File menu > Upload to Sketchfab

History:        1.0 (7/13/2012):
                - First release
                1.1 (7/18/2012):
                - Changed json assembly to Ruby side - more reliable
                - Uploads large models now
                1.2 (7/19/2012):
                - Uploads a thumbnail now
                - Provided more error checking
                1.3 (7/20/2012):
                - Fixed filename problem to prevent permission issue
                1.4 (12/11/2012):
                - Support for updated API (incl. private/password functionailty)
                - Included SketchUp source tag in JSON
                - Exports edges by default now
                - Removed thumbnail upload (not supported anymore by API)
                - Better string cleaning on upload
                1.5 (5/10/2013):
                - Reorganized folders
                1.6 (7/15/2013):
                - Changed temp location to user folder to remove permission problem
                1.7 (2/18/2014):
                - Fixed temp location cleanup
                - Removed thumbnail image export
                  SU 2014 only:
                - Added new upload method
                - Implemented multipart upload via new API
                - Added option to open model after uploading
                1.8 (3/8/2014):
                - Uploads ZIPped models now
                - Gives option to only upload selection if something has been selected.
                - SketchUp material names are now preserved on upload.
                - SU 2014 only: Option to include/exclude edges
                2.0 (3/11/2014):
                - Added more export options to dialog (2014)
                - Added error handling in uploading code (2014)
                - Changed upload to SSL (2014), 2013 was always SSL
                2.1 (3/17/2014):
                - Wrapped external modules in my namespace
                - Consolidated code
                - Switched export location to TEMP folder
                TBD:
                - Code cleanup


Issues/To-do:
                - For versions before SU 2014: the post_url function does not accept returned data.
                - Text labels, dimensions, construction-points and -lines, images etc. don't upload (by design)


Credits:

  Clément (zqsd) for the DAE ZIP solution.


Licenses:

  multipart-post
  ==============

    https://github.com/nicksieger/multipart-post

    Copyright (c) 2007-2013 Nick Sieger nick@nicksieger.com

    Permission is hereby granted, free of charge, to any person obtaining a copy of this
    software and associated documentation files (the 'Software'), to deal in the Software without
    restriction, including without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom
    the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
    OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
    AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
    THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


  7-zip:
  ======

    7-Zip Command line version
    ~~~~~~~~~~~~~~~~~~~~~~~~~~
    License for use and distribution
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    7-Zip Copyright (C) 1999-2010 Igor Pavlov.

    7za.exe is distributed under the GNU LGPL license

    Notes:
      You can use 7-Zip on any computer, including a computer in a commercial
      organization. You don't need to register or pay for 7-Zip.


    GNU LGPL information
    --------------------

      This library is free software; you can redistribute it and/or
      modify it under the terms of the GNU Lesser General Public
      License as published by the Free Software Foundation; either
      version 2.1 of the License, or (at your option) any later version.

      This library is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
      Lesser General Public License for more details.

      You can receive a copy of the GNU Lesser General Public License from
      http://www.gnu.org/

=end


# ========================


require 'sketchup'
require 'extensions'


# ========================


as_sketchfab = SketchupExtension.new "Sketchfab Uploader", "as_sketchfab/as_sketchfab_uploader.rb"
as_sketchfab.copyright= 'Copyright 2012-2014 Alexander C. Schreyer'
as_sketchfab.creator= 'Alexander C. Schreyer, www.alexschreyer.net'
as_sketchfab.version = '2.1'
as_sketchfab.description = "Uploads the current model (or the selection) to the Sketchfab.com website."
Sketchup.register_extension as_sketchfab, true


# ========================