# Loader for as_plugins/as_sketchfab/as_sketchfab_uploader.rb

require 'sketchup.rb'
require 'extensions.rb'

as_sketchfab = SketchupExtension.new "Sketchfab Uploader", "as_sketchfab/as_sketchfab_uploader.rb"
as_sketchfab.copyright= 'Copyright 2012 Alexander C. Schreyer'
as_sketchfab.creator= 'Alexander C. Schreyer, www.alexschreyer.net'
as_sketchfab.version = '1.5'
as_sketchfab.description = "A plugin to upload the current model to the Sketchfab website."
Sketchup.register_extension as_sketchfab, true
