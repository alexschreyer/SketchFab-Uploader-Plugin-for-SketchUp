module AS_SketchfabUploader
# A small module to zip files

    module Zip
    
        def self.create(zip_name, *files)
        
            # Are we on Windows? Need to do it this way for 2013 and 2014
            if ((/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil)
            
                # Prepare 7-Zip file location
                sevenZip = File.join(File.dirname(__FILE__), '7za.exe')
                sevenZip.gsub!(/\\/,'/')
                sevenZip.gsub!('/lib','/bin')
                
                # Assemble Win system command
                all_files =  files.join("\" \"")  
                command = "\"#{sevenZip}\" a \"#{zip_name}\" \"#{all_files}\""
                
                # And execute it!
                system command
                
            else
            
                # On the Mac use built-in ZIP function
                system "zip -r #{zip_name} #{files.join(' ')}"
                
            end
            
        end
    
    end

end
