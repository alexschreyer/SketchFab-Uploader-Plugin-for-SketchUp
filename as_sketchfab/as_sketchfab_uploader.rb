# ========================
# Main file for Sketchfab Uploader
# ========================


require 'sketchup.rb'


# ========================
    

module AS_Extensions

  module AS_SketchfabUploader


      # ========================


      # Some general variables
      
      # Extension name for defaults etc. w/backcomp
      @extdir = File.dirname(__FILE__).gsub(%r{//}) { "/" }

      # Set temporary folder locations and filenames
      # Don't use root or plugin folders because of writing permissions
      
      # Get temp directory for temporary file storage
      @user_dir = (defined? Sketchup.temp_dir) ? Sketchup.temp_dir : ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP']
      Sketchup.write_default @extname, "user_dir", @user_dir
      
      # Cleanup slashes
      @user_dir = @user_dir.tr("\\","/")
      @filename = File.join(@user_dir , 'temp_export.dae')
      @asset_dir = File.join(@user_dir, 'temp_export')
      @zip_name = File.join(@user_dir,'temp_export.zip')

      # Exporter options - doesn't work with KMZ export, though
      # Need to have instancing false as per Sketchfab
      @options_hash = { :triangulated_faces   => true,
                        :doublesided_faces    => false,
                        :edges                => true,
                        :materials_by_layer   => false,
                        :author_attribution   => true,
                        :texture_maps         => true,
                        :selectionset_only    => false,
                        :preserve_instancing  => false }

      # Load my libraries
      require_relative 'lib/zip'
      require_relative 'lib/multipart-post-as'
      
      # Load other libraries
      require 'uri'
      require 'net/http'
      require 'net/https'
      require 'openssl'
      require 'json'
      require 'fileutils'      


      # ========================


      def self.show_dialog_2014
      # This uses the Ruby StdLibs and the v3 API (only newer than 2014)
      
          # Check that we have < 100 materials
          matnum = Sketchup.active_model.materials.length
          if matnum >= 100
              res = UI.messagebox "Your model has #{matnum} materials. Sketchfab only accepts 100 materials. Do you still want to proceed with the upload (some materials may be discarded)?", MB_YESNO
              return if res == 7
          end

          # Allow for only selection upload if something is selected - reset var first
          @options_hash[:selectionset_only] = false
          if (Sketchup.active_model.selection.length > 0) then
              res = UI.messagebox "Upload only selected geometry?", MB_YESNO
              @options_hash[:selectionset_only] = true if (res == 6)
          end

          # Set up and show Webdialog
          dlg = UI::WebDialog.new('Sketchfab Uploader', false,'SketchfabUploader', 450, 520, 150, 150, true)
          dlg.navigation_buttons_enabled = false
          dlg.min_width = 450
          dlg.min_height = 680
          # dlg.max_width = 450
          dlg.set_size(450,680)

          # Close dialog callback
          dlg.add_action_callback('close_me') {|d, p|

              d.close

          }


          # Callback to prefill page elements (token)
          dlg.add_action_callback('prefill') {|d, p|

              # Prefill all form elements from registry and model here
              # Need to do this as callback because we need to wait until HTML page has loaded
              
              # Get registry data for general settings
              mytoken = Sketchup.read_default @extname, "api_token"
              edg = Sketchup.read_default @extname, "edges", "true"
              mat = Sketchup.read_default @extname, "materials", "false"  
              tex = Sketchup.read_default @extname, "textures", "true"
              fac = Sketchup.read_default @extname, "faces", "false"
              
              # Get model data for model settings
              mytitle = Sketchup.active_model.get_attribute 'sketchfab', 'model_title', ''
              description = Sketchup.active_model.get_attribute 'sketchfab', 'model_description', ''
              tags = Sketchup.active_model.get_attribute 'sketchfab', 'model_tags', 'sketchup'
              private = Sketchup.active_model.get_attribute('sketchfab', 'model_private', 'false').downcase
              password = Sketchup.active_model.get_attribute 'sketchfab', 'model_password', ''      
              
              # Send data to dialog
              c = "$('#token').val('#{mytoken}');"
              d.execute_script(c)              
              c = "$('#edges').prop('checked',#{edg}); $('#materials').prop('checked',#{mat}); $('#textures').prop('checked',#{tex}); $('#faces').prop('checked',#{fac});"
              d.execute_script(c)
              c = "$('#edges').val(#{edg}); $('#materials').val(#{mat}); $('#textures').val(#{tex}); $('#faces').val(#{fac});"
              d.execute_script(c)
              c = "$('#mytitle').val('#{mytitle}'); $('#description').val('#{description}'); $('#tags').val('#{tags}'); $('#password').val('#{password}');"
              d.execute_script(c)
              if private == 'true'
                c = "$('#private').prop('checked',#{private}); $('#private').val(#{private}); $('#pw-field').toggle();"
                d.execute_script(c)
              end

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
              edg = d.get_element_value("edges").gsub(/"/, "'")
              mat = d.get_element_value("materials").gsub(/"/, "'")
              tex = d.get_element_value("textures").gsub(/"/, "'")
              fac = d.get_element_value("faces").gsub(/"/, "'")
              # ins = d.get_element_value("instances").gsub(/"/, "'")
              
              # Write form elements to registry here
              Sketchup.write_default @extname, "api_token", p
              Sketchup.write_default @extname, "edges", edg
              Sketchup.write_default @extname, "materials", mat              
              Sketchup.write_default @extname, "textures", tex
              Sketchup.write_default @extname, "faces", fac
              # Sketchup.write_default @extname, "instances", ins
              
              # Write form elements to model here
              Sketchup.active_model.set_attribute 'sketchfab', 'model_title', mytitle
              Sketchup.active_model.set_attribute 'sketchfab', 'model_description', description
              Sketchup.active_model.set_attribute 'sketchfab', 'model_tags', tags
              Sketchup.active_model.set_attribute 'sketchfab', 'model_private', private
              Sketchup.active_model.set_attribute 'sketchfab', 'model_password', password
              
              # Adjust options from dialog
              (edg == "true") ? @options_hash[:edges] = true : @options_hash[:edges] = false
              (mat == "true") ? @options_hash[:materials_by_layer] = true : @options_hash[:materials_by_layer] = false
              (tex == "true") ? @options_hash[:texture_maps] = true : @options_hash[:texture_maps] = false
              (fac == "true") ? @options_hash[:doublesided_faces] = true : @options_hash[:doublesided_faces] = false
              # (ins == "true") ? @options_hash[:preserve_instancing] = true : @options_hash[:preserve_instancing] = false
              
              # Export model as DAE and process
              if Sketchup.active_model.export @filename, @options_hash then

                  # Some feedback while we wait
                  d.execute_script('submitted()')

                  # Wrap in rescue for error display
                  begin

                      # Create ZIP file
                      Zip.create(@zip_name, @filename, @asset_dir)
                      upfile = AS_SketchfabUploader::UploadIO.new(@zip_name, "application/zip")

                      # Compile data
                      data = {
                                'modelFile' => upfile,
                                'name' => mytitle,
                                'description' => description,
                                'tags' => tags.split(' '),
                                'private' => private,
                                'password' => password,
                                'isPublished' => false,
                                'source' => 'sketchup-exporter'
                      }

                      # Submission URL
                      url = 'https://api.sketchfab.com/v3/models'
                      
                      # Prepare data for submission
                      # Should we re-upload the file if it already exists on Sketchfab?   
                      @model_id = Sketchup.active_model.get_attribute 'sketchfab', 'model_id'
                      
                      if @model_id != nil and @model_id.length == 32
                      
                        result = UI.messagebox "Model has been previously uploaded. Do you want to update the existing model?\n\n'Yes' re-uploads model to Sketchfab (keeps model ID and preserves online edits, e.g. materials).\n'No' creates new file upload (and a new model ID).", MB_YESNO
                        
                        if result == 6  # Yes, re-upload
                        
                          data['isPublished'] = true  # Don't revert back to draft by default
                          url += '/' + @model_id.to_s 
                          uri = URI.parse(url)
                          req = AS_SketchfabUploader::Multipart_Put.new uri.path, data
                          
                        else  # Upload as new model
                        
                          uri = URI.parse(url)
                          req = AS_SketchfabUploader::Multipart_Post.new uri.path, data  
                          
                        end
                        
                      else  # Upload new model
                      
                        uri = URI.parse(url)
                        req = AS_SketchfabUploader::Multipart_Post.new uri.path, data  
                      
                      end
                     
                      # Add token to header for authorization
                      req.add_field("Authorization", "Token #{p}")

                      # Submit via SSL
                      https = Net::HTTP.new(uri.host, uri.port)
                      # https.set_debug_output($stdout)  # Debug only
                      https.use_ssl = true     
                      # Can't properly verify certificate with Sketchfab - OK here
                      https.verify_mode = OpenSSL::SSL::VERIFY_NONE      

                      res = https.start { |cnt| cnt.request(req) }
                      p "Sketchfab response: #{res.code} #{res.msg}"
                      # p res.body  # Debug only
                      
                      res.code.to_i < 400 ? @success = true : @success = false

                      # Free some resources
                      upfile.close
                      GC.start

                  rescue Exception => e

                      UI.messagebox e

                  end

                  d.close

                  if @success then
                  
                      begin
                  
                          # Now extract the resulting data
                          json = JSON.parse(res.body)

                          # Get model info from result
                          @model_id = json['uid']
                          @model_data_uri = json['uri']

                          # Write the model ID to the file as attributes (for later)
                          Sketchup.active_model.set_attribute 'sketchfab', 'model_id', @model_id
                      
                      rescue
                      
                      end
                      
                      # Give option to open uploaded model
                      result = UI.messagebox 'Open Sketchfab model in your browser?', MB_YESNO
                      UI.openURL "https://sketchfab.com/models/#{@model_id}" if result == 6

                  else

                      fb = "Error: \n"
                      fb += json['error'].to_s + "\n" if json
                      fb += "#{res.code} #{res.msg}" if res
                      UI.messagebox "Sketchfab upload failed. " + fb

                  end

                  begin

                      # Then delete the temporary files
                      # File.delete @zip_name if File.exists?(@zip_name)
                      # File.delete @filename if File.exists?(@filename)
                      FileUtils.rm_f(@zip_name) if File.exists?(@zip_name)
                      FileUtils.rm_f(@filename) if File.exists?(@filename)
                      FileUtils.rm_r(@asset_dir) if File.exists?(@asset_dir)

                  rescue Exception => e

                      UI.messagebox e

                  end

              else

                  d.close
                  UI.messagebox "Couldn't export model as " + @filename

              end

          }


          # Set dialog HTML from external file
          dlg.set_file(File.join(@extdir,'as_sketchfab_form2014.html'))
          dlg.show_modal


      end # show_dialog_2014
      
      
      # ========================      
      

      def self.set_model_id
      # Allow to set model id (for re-uploads)
      
        @model_id = Sketchup.active_model.get_attribute 'sketchfab', 'model_id'
        res = UI.inputbox(['Sketchfab Model ID '], [@model_id], 'Edit Sketchfab Model ID Stored in File')
        Sketchup.active_model.set_attribute 'sketchfab', 'model_id', res[0] if res
      
      end # set_model_id  
      

      # ========================
      
      def self.show_help
      # Show the website as an About dialog
      
        title = @exttitle + ' - Help'
        url = 'http://alexschreyer.net/projects/sketchfab-uploader-plugin-for-sketchup/'

        if Sketchup.version.to_f < 17 then  # Use old method
          d = UI::WebDialog.new( title , true ,
            title.gsub(/\s+/, "_") , 1000 , 600 , 100 , 100 , true);
          d.navigation_buttons_enabled = false
          d.set_url( url )
          d.show      
        else
          d = UI::HtmlDialog.new( { :dialog_title => title, :width => 1000, :height => 600,
            :style => UI::HtmlDialog::STYLE_DIALOG, :preferences_key => title.gsub(/\s+/, "_") } )
          d.set_url( url )
          d.show
          d.center
        end          
      
      end # show_help     


      # ========================

      # Create menu items
      unless file_loaded?(__FILE__)
      
        sub = UI.menu("File").add_submenu( "Upload to Sketchfab" )
        # Pick based on version
        if Sketchup.version.to_f < 14 then
          sub.add_item("Upload Model...") { UI.messagebox "This Sketchfab uploader version is not compatible with your version of SketchUp." }
        else
          sub.add_item("Upload Model...") { self.show_dialog_2014 }
        end
        sub.add_item("Edit Model ID") { self.set_model_id }
        sub.add_item("Help") { self.show_help }

        file_loaded(__FILE__)

      end


  end # module AS_SketchfabUploader

end # module AS_Extensions


# ========================
