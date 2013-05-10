=begin
Copyright 2012, Alexander C. Schreyer
All Rights Reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net
Website:        http://www.alexschreyer.net/projects/

Name :          Sketchfab Uploader
Version:        1.5
Date :          5/10/2013

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

Issues:
                - The post_url function does not accept returned data.

=end

require 'sketchup'

module AS_SketchfabUploader

    def self.show_dialog
    
        # Get currently open model
        mod = Sketchup.active_model 

        # Set temporary filenames
        # Don't use root folders because of writing permissions
        filename = File.join(File.dirname(__FILE__) , 'temp_export.kmz')
        i_filename = File.join(File.dirname(__FILE__) , 'temp_export.png')

        # Exporter options
        options_hash = {  :triangulated_faces   => true,
                          :doublesided_faces    => true,
                          :edges                => true,
                          :materials_by_layer   => false,
                          :author_attribution   => true,
                          :texture_maps         => true,
                          :selectionset_only    => false,
                          :preserve_instancing  => true }
        
        # Export model as KMZ
        if mod.export filename, options_hash then
            
            # Open file as binary and encode it as Base64
            contents = open(filename, "rb") {|io| io.read }
            encdata = [contents].pack('m')
            
            # Image exporter keys
            keys = {    :filename => i_filename,
                        :width => 448,
                        :height => 280,
                        :antialias => true,
                        :compression => 0.5,
                        :transparent => false  } 
                        
            # Export thumbnail image and encode it
            view = mod.active_view  
            view.write_image keys
            i_contents = open(i_filename, "rb") {|io| io.read }
            i_encdata = [i_contents].pack('m')
            
            # Then delete the temporary files - keep them for debugging
            # File.delete filename
            # File.delete i_filename
            
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
                json = '{"contents":"' + encdata.split(/[\r\n]+/).join('\r\n') + '","filename":"temp.zip","title":"' + mytitle + '","description":"' + description + '","tags":"' + tags + '","token":"' + p + '","source":"sketchup-version"' + privString + '}'
                # UI.messagebox json
                
                # Submit data to Sketchfab - need to use old API with JSON
                d.post_url("https://api.sketchfab.com/model", json)
                
                # New API attempt - doesn't work this way:
                # json = '{"fileModel":"' + encdata.split(/[\r\n]+/).join('\r\n') + '","filenameModel":"temp.zip","title":"' + mytitle + '","description":"' + description + '","tags":"' + tags + '","token":"' + p + '","source":"sketchup-version"' + privString + '}'                
                # d.post_url("https://api.sketchfab.com/v1/models", json)
                
                defaults = Sketchup.write_default "Sketchfab", "api_token", p
                d.execute_script('submitted()')
                # Open Sketchfab Dashboard after submitting - disabled for now:
                # sleep(3)
                # UI.openURL "http://www.sketchfab.com/dashboard/"
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
            <p><span style="float:left;"><button value="Cancel" id="cancel">Dismiss</button></span><span style="float:right;margin-top:10px;">&copy; 2012 by <a href="http://www.alexschreyer.net/" title="http://www.alexschreyer.net/" target="_blank" style="color:orange">Alex Schreyer</a></span></p>
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
        
            UI.messagebox "Couldn't export model as " + filename
            
        end # if image converts
    
    end # show_dialog
    
end # module

# Create menu items
unless file_loaded?(__FILE__)

    UI.menu("File").add_item("Upload to Sketchfab") {AS_SketchfabUploader::show_dialog}
    file_loaded(__FILE__)
 
end
