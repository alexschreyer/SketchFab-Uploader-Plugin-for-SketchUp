=begin
Copyright 2012-2014, Alexander C. Schreyer
All Rights Reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/sketchfab-uploader-plugin-for-sketchup/

Name :          Sketchfab Uploader
Version:        1.7
Date :          2/18/2014

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

Issues:
                - For versions before SU 2014: the post_url function does not accept returned data.
                
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


=end


# ========================


require 'sketchup'


# ========================
    

module AS_SketchfabUploader

    # Some general variables

    # Set temporary folder locations and filenames
    # Don't use root or plugin folders because of writing permissions
    # Get user directory for temporary file storage
    @user_dir = (ENV['USERPROFILE'] != nil) ? ENV['USERPROFILE'] :
                ( (ENV['HOME'] != nil) ? ENV['HOME'] : 
                File.dirname(__FILE__) )
    # Cleanup slashes
    @user_dir = @user_dir.tr("\\","/")
    @filename = File.join(@user_dir , 'temp_export.kmz')
    
    # Exporter options - doesn't work with KMZ export, though
    @options_hash = {  :triangulated_faces   => true,
                      :doublesided_faces    => true,
                      :edges                => true,
                      :materials_by_layer   => false,
                      :author_attribution   => true,
                      :texture_maps         => true,
                      :selectionset_only    => false,
                      :preserve_instancing  => true }    
    
    
    # ========================    
   

    def self.show_dialog_2013
    # This uses a json approach to upload (for < SU 2014)
        
        # Export model as KMZ
        if Sketchup.active_model.export @filename, @options_hash then
            
            # Open file as binary and encode it as Base64
            contents = open(@filename, "rb") {|io| io.read }
            encdata = [contents].pack('m')
            
            # Then delete the temporary files
            # File.delete @filename
            
            # Set up and show Webdialog
            dlg = UI::WebDialog.new('Sketchfab Uploader', false,'SketchfabUploader', 450, 520, 150, 150, true)
            dlg.navigation_buttons_enabled = false
            dlg.min_width = 450
            dlg.max_width = 450
            dlg.set_size(450,650)
            logo = File.join(File.dirname(__FILE__) , 'uploader-logo.png')
            
            # Close dialog callback
            dlg.add_action_callback('close_me') {|d, p|    
                d.close
            }
            
            # Callback to prefill page elements (token)
            dlg.add_action_callback('prefill') {|d, p|   
                # Need to do this because we need to wait until page has loaded
                mytoken = Sketchup.read_default "Sketchfab", "api_token", "Paste your token here"
                c = "$('#token').val('" + mytoken + "')"
                d.execute_script(c)
            }
            
            # Callback to send model
            dlg.add_action_callback('send') {|d, p|   
            
                # Get data from webdialog and clean it up a bit
                description = d.get_element_value("description").gsub(/"/, "'")
                mytitle = d.get_element_value("mytitle").gsub(/"/, "'")
                tags = d.get_element_value("tags").gsub(/"/, "'")
                tags.gsub!(/,*\s+/,' ')
                private = d.get_element_value("private").gsub(/"/, "'")
                password = d.get_element_value("password").gsub(/"/, "'")
                privString = ''
                if private == 'True' then
                    privString = ',"private":"true","password":"' + password + '"'
                end
                
                # Assemble JSON string
                json = '{"contents":"' + encdata.split(/[\r\n]+/).join('\r\n') + '","filename":"temp.zip","title":"' + mytitle + '","description":"' + description + '","tags":"' + tags + '","token":"' + p + '","source":"sketchup-exporter"' + privString + '}'
                
                # Submit data to Sketchfab - need to use old API with JSON
                d.post_url("https://api.sketchfab.com/model", json)
                
                defaults = Sketchup.write_default "Sketchfab", "api_token", p
                d.execute_script('submitted()')
                
            }
    
            dlg_html = %Q~
            <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
            <html xmlns="http://www.w3.org/1999/xhtml"><head><title>Sketchfab.com Uploader</title>
            <style type="text/css">
                * {font-family: Arial, Helvetica, sans-serif; font-size:13px;}
                body {background-color:#3d3d3d;padding:10px;min-width:220px;}
                h1, label, p {color:#eee; font-weight: bold;}
                h1 {font-size:2em;color:orange}
                a, a:hover, a:visited {color:orange}
                input, button, textarea {color:#fff; background-color:#666; border:none;}
                label {display: block; width: 150px;float: left;}
            </style>
            <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
            </head>
            <body>
            <img src="~ + logo + %Q~" style="width:100%;" />
            <p id="text">This dialog uploads the currently open model to Sketchfab.com. All fields marked with a * are mandatory.
            You can get your API token from the <a href='http://sketchfab.com' title='http://sketchfab.com' target='_blank'>Sketchfab website</a> after registering there.</p>
            <form id="SketchfabSubmit" name="SketchfabSubmit" action="">
                <p><label for="mytitle">Model title *</label><input type="text" id="mytitle" name="mytitle" style="width:200px;" /></p>
                <p><label for="description">Description</label><textarea name="description" id="description" style="height:3em;width:200px;"></textarea></p>
                <p><label for="tags">Tags (space-separated)</label><input type="text" id="tags" name="tags" value="sketchup" style="width:200px;" /></p>
                <p><label for="private">Make model private?</label><input type="checkbox" name="private" id="private" value="" /> <span style="font-weight:normal;">(PRO account required)</span></p>
                <p id="pw-field" style="display:none;"><label for="password">Password</label><input type="text" name="password" id="password" value="" style="width:200px;" /></p>
                <p><label for="token">Your API token *</label><input type="text" name="token" id="token" value="" style="width:200px;" /></p>
                <p><input type="submit" id="submit" value="Submit Model" style="font-weight:bold;" /></p>
            </form>
            <p><span style="float:left;"><button value="Cancel" id="cancel">Dismiss</button></span><span style="float:right;margin-top:10px;">&copy; 2012-2014 by <a href="http://www.alexschreyer.net/" title="http://www.alexschreyer.net/" target="_blank" style="color:orange">Alex Schreyer</a></span></p>
            <p></p>
            <script type="text/javascript">
            $(function(){
              $("#SketchfabSubmit").submit(function(event){
                    event.preventDefault();
                    
                    if ($('#mytitle').val().length == 0) {
                        alert('You must fill in a title.');
                        return false;
                    }
    
                    if ($('#token').val().length < 32) {
                        alert('Your token looks like it is too short. Please double-check.');
                        return false;
                    }
                    
                    // Submit form and give feedback
                    token = $('#token').val();
                    window.location='skp:send@'+token;
              });
            });
            $('#cancel').click(function(){
                window.location='skp:close_me'; 
            });
            
            $('#private').click(function(){
                if ($(this).val() == 'True') {
                    $(this).val('');
                } else {
                    $(this).val('True');
                };
                $('#pw-field').toggle(); 
            });
            
            $(document).ready(function() {
                window.location='skp:prefill';
            });
            
            function submitted() {
                $('h1').html('Model Submitted');
                scomment = "Your model has been submitted. You can soon find it on your <a href='http://sketchfab.com/dashboard/' title='http://sketchfab.com/dashboard/' target='_blank'>Sketchfab dashboard</a>.<br /><br />"+
                "Before closing this dialog, please wait until:<br /><br />"+
                "<i>On Windows:</i> a browser download dialog opens (you can cancel it).<br /><br />"+
                "<i>On the Mac:</i> this dialog changes into a confirmation code (close it afterwards).";
                $('#text').html(scomment);
                $('form').html('');                  
            };        
            
            </script>
            </body></html>
            ~ # End of HTML
            
            dlg.set_html(dlg_html)
            dlg.show_modal   
            
        else
        
            UI.messagebox "Couldn't export model as " + @filename
            
        end # if image converts
    
    end # show_dialog_2013
    
    
    # ========================

    
    def self.show_dialog_2014
    # This uses the Ruby NET StdLibs instead of json


        # Load Net and multipart post libraries
        $: << File.dirname(__FILE__)+'/lib'
        require 'net/http'
        require 'json'
        require 'net/http/post/multipart'
        

        # Set up and show Webdialog
        dlg = UI::WebDialog.new('Sketchfab Uploader', false,'SketchfabUploader', 450, 520, 150, 150, true)
        dlg.navigation_buttons_enabled = false
        dlg.min_width = 450
        dlg.max_width = 450
        dlg.set_size(450,650)
        logo = File.join(File.dirname(__FILE__) , 'uploader-logo.png')
        
        
        # Close dialog callback
        dlg.add_action_callback('close_me') {|d, p|    
        
            d.close
            
        }
        
        
        # Callback to prefill page elements (token)
        dlg.add_action_callback('prefill') {|d, p|   
        
            # Need to do this because we need to wait until page has loaded
            mytoken = Sketchup.read_default "as_Sketchfab", "api_token", "Paste your token here"
            c = "$('#token').val('" + mytoken + "')"
            d.execute_script(c)
            
        }
        
        
        # Callback to prepare and send model
        dlg.add_action_callback('send') {|d, p|   
        
            # Get data from webdialog and clean it up a bit
            # Token is p
            description = d.get_element_value("description").gsub(/"/, "'")
            mytitle = d.get_element_value("mytitle").gsub(/"/, "'")
            tags = d.get_element_value("tags").gsub(/"/, "'")
            tags.gsub!(/,*\s+/,' ')
            private = d.get_element_value("private").gsub(/"/, "'")
            password = d.get_element_value("password").gsub(/"/, "'")
            
            # Export model as KMZ and process
            if Sketchup.active_model.export @filename, @options_hash then
                
                # Some feedback while we wait
                d.execute_script('submitted()')               
                
                # Open file for multipart upload
                encdata = UploadIO.new(File.new(@filename), "application/zip", "model.kmz")
                
                # Then delete the temporary file
                # File.delete @filename
            
                # Submission URL
                url = URI.parse('http://api.sketchfab.com/v1/models')
                
                # Prepare data for submission
                req = Net::HTTP::Post::Multipart.new url.path,
                          'token' => p,
                          'fileModel' => encdata,
                          'title' => mytitle,
                          'description' => description,
                          'tags' => tags,
                          'private' => private,
                          'password' => password,
                          'source' => 'sketchup-exporter'
                
                # And submit it
                res = Net::HTTP.start(url.host, url.port) do |http|
                  http.request(req)
                end
                json = JSON.parse(res.body.gsub(/"/,"\""))
                
                @success = json['success']
                if @success then 
                
                    # Get model info from result
                    @model_id = json['result']['id']
                    
                    d.close
                    # Give option to open uploaded model
                    result = UI.messagebox 'Open Sketchfab model in default browser?', MB_YESNO
                    UI.openURL "https://sketchfab.com/show/#{@model_id}" if result == 6  
                    
                else
                
                    d.close
                    UI.messagebox "Sketchfab upload failed. Error: " + json['error']
                
                end
                
                # Save token for the next time
                defaults = Sketchup.write_default "as_Sketchfab", "api_token", p                
                
            else 
            
                d.close
                UI.messagebox "Couldn't export model as " + @filename
            
            end

        }
        
        
        # Set dialog HTML
        dlg_html = %Q~
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml"><head><title>Sketchfab.com Uploader</title>
        <style type="text/css">
            * {font-family: Arial, Helvetica, sans-serif; font-size:13px;}
            body {background-color:#3d3d3d;padding:10px;min-width:220px;}
            h1, label, p {color:#eee; font-weight: bold;}
            h1 {font-size:2em;color:orange}
            a, a:hover, a:visited {color:orange}
            input, button, textarea {color:#fff; background-color:#666; border:none;}
            label {display: block; width: 150px;float: left;}
        </style>
        <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
        </head>
        <body>
        <img src="~ + logo + %Q~" style="width:100%;" />
        <p id="text">This dialog uploads the currently open model to Sketchfab.com. All fields marked with a * are mandatory.
        You can get your API token from the <a href='http://sketchfab.com' title='http://sketchfab.com' target='_blank'>Sketchfab website</a> after registering there.</p>
        <form id="SketchfabSubmit" name="SketchfabSubmit" action="">
            <p><label for="mytitle">Model title *</label><input type="text" id="mytitle" name="mytitle" style="width:200px;" /></p>
            <p><label for="description">Description</label><textarea name="description" id="description" style="height:3em;width:200px;"></textarea></p>
            <p><label for="tags">Tags (space-separated)</label><input type="text" id="tags" name="tags" value="sketchup" style="width:200px;" /></p>
            <p><label for="private">Make model private?</label><input type="checkbox" name="private" id="private" value="" /> <span style="font-weight:normal;">(PRO account required)</span></p>
            <p id="pw-field" style="display:none;"><label for="password">Password</label><input type="text" name="password" id="password" value="" style="width:200px;" /></p>
            <p><label for="token">Your API token *</label><input type="text" name="token" id="token" value="" style="width:200px;" /></p>
            <p><input type="submit" id="submit" value="Submit Model" style="font-weight:bold;" /></p>
        </form>
        <p><span style="float:left;"><button value="Cancel" id="cancel">Dismiss</button></span><span style="float:right;margin-top:10px;">&copy; 2012-2014 by <a href="http://www.alexschreyer.net/" title="http://www.alexschreyer.net/" target="_blank" style="color:orange">Alex Schreyer</a></span></p>
        <p></p>
        <script type="text/javascript">
        $(function(){
          $("#SketchfabSubmit").submit(function(event){
                event.preventDefault();
                
                if ($('#mytitle').val().length == 0) {
                    alert('You must fill in a title.');
                    return false;
                }

                if ($('#token').val().length < 32) {
                    alert('Your token looks like it is too short. Please double-check.');
                    return false;
                }
                
                // Submit form and give feedback
                token = $('#token').val();
                window.location='skp:send@'+token;
          });
        });
        $('#cancel').click(function(){
            window.location='skp:close_me'; 
        });
        
        $('#private').click(function(){
            if ($(this).val() == 'True') {
                $(this).val('');
            } else {
                $(this).val('True');
            };
            $('#pw-field').toggle(); 
        });
        
        $(document).ready(function() {
            window.location='skp:prefill';
        });
        
        function submitted() {
            $('h1').html('Processing...');
            scomment = 'Your model has been submitted. Please hang on while we wait for a response from Sketchfab.';
            $('#text').html(scomment);
            $('form').html('');
        };        
        
        </script>
        </body></html>
        ~ # End of HTML
        dlg.set_html(dlg_html)
        dlg.show_modal    
        
    
    end # show_dialog_2014
    
    
    # ========================    
    
    
end # module


# ========================


# Create menu items
unless file_loaded?(__FILE__)

  # Pick based on version
  if Sketchup.version.to_f < 14 then
    UI.menu("File").add_item("Upload to Sketchfab") {AS_SketchfabUploader::show_dialog_2013} 
  else
    UI.menu("File").add_item("Upload to Sketchfab") {AS_SketchfabUploader::show_dialog_2014} 
  end
  
  file_loaded(__FILE__)
 
end
