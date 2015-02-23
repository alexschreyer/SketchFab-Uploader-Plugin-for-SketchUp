# Couldn't namespace for AS, customized name for class instead

#--
# Copyright (c) 2007-2012 Nick Sieger.
# See the file README.txt included with the distribution for
# software license details.
#++

require 'net/http'
require 'stringio'
require 'cgi'
require 'composite_io'
require 'multipartable'
require 'parts'

module AS_SketchfabUploader

      class AS_Multipart < Net::HTTP::Post
        include Multipartable
      end

end


# module Net #:nodoc:
#   class HTTP #:nodoc:
#     class Post #:nodoc:
#       class AS_Multipart < Post
#         include Multipartable
#       end
#     end
#   end
# end