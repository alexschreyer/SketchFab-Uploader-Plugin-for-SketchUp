SketchFab Uploader Plugin for SketchUp
======================================

Copyright 2012-2013, Alexander C. Schreyer
All Rights Reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/

Name :          Sketchfab Uploader

Version:        1.4

Date :          12/11/2012

Description :   This plugin uploads the currently open model to Sketchfab.com

Usage :         File menu > Upload to Sketchfab

History:

                1.0 (7/13/2012):
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

Issues:

                - The post_url function does not accept returned data.
