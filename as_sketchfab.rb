=begin
Copyright 2012-2018, Alexander C. Schreyer
All Rights Reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/sketchfab-uploader-plugin-for-sketchup/

Name :          Sketchfab Uploader

Version:        2.5
Date :          9/13/2018

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
                2.2 (1/18/2016):
                - Code cleanup, wrapped in my module for consistency
                - Updated Sketchfab logo
                - Token field hides content (password input)
                - Removed support for instanced upload (doesn't work for Sketchfab)
                - Moved html dialogs into separate files
                - Included local version of jQuery, updated jQuery
                - Checkbox selection now saves state
                - Set maxlength for input fields
                2.3 (12/5/2016):
                - Fixed dialog issue in SU 2017 (min/max size)
                - Fixed extension loader code
                2.4 (12/12/2016):
                - Added help menu item
                - Code cleanup


Issues/To-do:
                - Still uses api v1, will update soon
                - Uses only model data stored in file, not from Sketchfab (e.g. if edited)
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


require 'sketchup.rb'
require 'extensions.rb'


# ========================


module AS_Extensions

  module AS_SketchfabUploader
  
    @extversion           = "2.5"
    @exttitle             = "Sketchfab Uploader"
    @extname              = "as_sketchfab"
    
    @extdir = File.dirname(__FILE__)
    @extdir.force_encoding('UTF-8') if @extdir.respond_to?(:force_encoding)
    
    loader = File.join( @extdir , @extname , "as_sketchfab_uploader.rb" )
   
    extension             = SketchupExtension.new( @exttitle , loader )
    extension.copyright   = "Copyright 2012-#{Time.now.year} Alexander C. Schreyer"
    extension.creator     = "Alexander C. Schreyer, www.alexschreyer.net"
    extension.version     = @extversion
    extension.description = "Uploads the current model (or the selection) to the Sketchfab.com website for interactive viewing in a browser. Allows for re-uploads."
    
    Sketchup.register_extension( extension , true )
         
  end  # module AS_SketchfabUploader
  
end  # module AS_Extensions


# ========================
