# Loader for as_sketchfab/as_sketchfab_uploader.rb

require 'sketchup'
require 'extensions'

as_sketchfab = SketchupExtension.new "Sketchfab Uploader", "as_sketchfab/as_sketchfab_uploader.rb"
as_sketchfab.copyright= 'Copyright 2012-2014 Alexander C. Schreyer'
as_sketchfab.creator= 'Alexander C. Schreyer, www.alexschreyer.net'
as_sketchfab.version = '1.7'
as_sketchfab.description = "A plugin to upload the current model to the Sketchfab website."
Sketchup.register_extension as_sketchfab, true
