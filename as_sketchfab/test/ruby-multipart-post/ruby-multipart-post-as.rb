module AS_SketchfabUploader
# This file namespaces and compiles the multipart-post library

#--
# Copyright (c) 2007-2012 Nick Sieger.
# See the file README.txt included with the distribution for
# software license details.
#++

require 'net/http'
require 'stringio'
require 'cgi'


# mutipart_post.rb

    module MultipartPost
      VERSION = "2.0.0"
    end

# composite_io.rb

    #--
    # Copyright (c) 2007-2012 Nick Sieger.
    # See the file README.txt included with the distribution for
    # software license details.
    #++

    # Concatenate together multiple IO objects into a single, composite IO object
    # for purposes of reading as a single stream.
    #
    # Usage:
    #
    #     crio = CompositeReadIO.new(StringIO.new('one'), StringIO.new('two'), StringIO.new('three'))
    #     puts crio.read # => "onetwothree"
    #
    class CompositeReadIO
      # Create a new composite-read IO from the arguments, all of which should
      # respond to #read in a manner consistent with IO.
      def initialize(*ios)
        @ios = ios.flatten
        @index = 0
      end

      # Read from IOs in order until `length` bytes have been received.
      def read(length = nil, outbuf = nil)
        got_result = false
        outbuf = outbuf ? outbuf.replace("") : ""

        while io = current_io
          if result = io.read(length)
            got_result ||= !result.nil?
            result.force_encoding("BINARY") if result.respond_to?(:force_encoding)
            outbuf << result
            length -= result.length if length
            break if length == 0
          end
          advance_io
        end
        (!got_result && length) ? nil : outbuf
      end

      def rewind
        @ios.each { |io| io.rewind }
        @index = 0
      end

      private

      def current_io
        @ios[@index]
      end

      def advance_io
        @index += 1
      end
    end

    # Convenience methods for dealing with files and IO that are to be uploaded.
    class UploadIO
      # Create an upload IO suitable for including in the params hash of a
      # Net::HTTP::Post::Multipart.
      #
      # Can take two forms. The first accepts a filename and content type, and
      # opens the file for reading (to be closed by finalizer).
      #
      # The second accepts an already-open IO, but also requires a third argument,
      # the filename from which it was opened (particularly useful/recommended if
      # uploading directly from a form in a framework, which often save the file to
      # an arbitrarily named RackMultipart file in /tmp).
      #
      # Usage:
      #
      #     UploadIO.new("file.txt", "text/plain")
      #     UploadIO.new(file_io, "text/plain", "file.txt")
      #
      attr_reader :content_type, :original_filename, :local_path, :io, :opts

      def initialize(filename_or_io, content_type, filename = nil, opts = {})
        io = filename_or_io
        local_path = ""
        if io.respond_to? :read
          # in Ruby 1.9.2, StringIOs no longer respond to path
          # (since they respond to :length, so we don't need their local path, see parts.rb:41)
          local_path = filename_or_io.respond_to?(:path) ? filename_or_io.path : "local.path"
        else
          io = File.open(filename_or_io)
          local_path = filename_or_io
        end
        filename ||= local_path

        @content_type = content_type
        @original_filename = File.basename(filename)
        @local_path = local_path
        @io = io
        @opts = opts
      end

      def self.convert!(io, content_type, original_filename, local_path)
        raise ArgumentError, "convert! has been removed. You must now wrap IOs using:\nUploadIO.new(filename_or_io, content_type, filename=nil)\nPlease update your code."
      end

      def method_missing(*args)
        @io.send(*args)
      end

      def respond_to?(meth, include_all = false)
        @io.respond_to?(meth, include_all) || super(meth, include_all)
      end
    end

# parts.rb

    module Parts
      module Part #:nodoc:
        def self.new(boundary, name, value, headers = {})
          headers ||= {} # avoid nil values
          if file?(value)
            FilePart.new(boundary, name, value, headers)
          else
            ParamPart.new(boundary, name, value, headers)
          end
        end

        def self.file?(value)
          value.respond_to?(:content_type) && value.respond_to?(:original_filename)
        end

        def length
          @part.length
        end

        def to_io
          @io
        end
      end

      class ParamPart
        include Part
        def initialize(boundary, name, value, headers = {})
          @part = build_part(boundary, name, value, headers)
          @io = StringIO.new(@part)
        end

        def length
         @part.bytesize
        end

        def build_part(boundary, name, value, headers = {})
          part = ''
          part << "--#{boundary}\r\n"
          part << "Content-Disposition: form-data; name=\"#{name.to_s}\"\r\n"
          part << "Content-Type: #{headers["Content-Type"]}\r\n" if headers["Content-Type"]
          part << "\r\n"
          part << "#{value}\r\n"
        end
      end

      # Represents a part to be filled from file IO.
      class FilePart
        include Part
        attr_reader :length
        def initialize(boundary, name, io, headers = {})
          file_length = io.respond_to?(:length) ?  io.length : File.size(io.local_path)
          @head = build_head(boundary, name, io.original_filename, io.content_type, file_length,
                             io.respond_to?(:opts) ? io.opts.merge(headers) : headers)
          @foot = "\r\n"
          @length = @head.bytesize + file_length + @foot.length
          @io = CompositeReadIO.new(StringIO.new(@head), io, StringIO.new(@foot))
        end

        def build_head(boundary, name, filename, type, content_len, opts = {}, headers = {})
          trans_encoding = opts["Content-Transfer-Encoding"] || "binary"
          content_disposition = opts["Content-Disposition"] || "form-data"

          part = ''
          part << "--#{boundary}\r\n"
          part << "Content-Disposition: #{content_disposition}; name=\"#{name.to_s}\"; filename=\"#{filename}\"\r\n"
          part << "Content-Length: #{content_len}\r\n"
          if content_id = opts["Content-ID"]
            part << "Content-ID: #{content_id}\r\n"
          end

          if headers["Content-Type"] != nil
            part <<  "Content-Type: " + headers["Content-Type"] + "\r\n"
          else
            part << "Content-Type: #{type}\r\n"
          end

          part << "Content-Transfer-Encoding: #{trans_encoding}\r\n"
          part << "\r\n"
        end
      end

      # Represents the epilogue or closing boundary.
      class EpiloguePart
        include Part
        def initialize(boundary)
          @part = "--#{boundary}--\r\n\r\n"
          @io = StringIO.new(@part)
        end
      end
    end

# multipartable.rb

    module Multipartable
      DEFAULT_BOUNDARY = "-----------RubyMultipartPost"
      def initialize(path, params, headers={}, boundary = DEFAULT_BOUNDARY)
        headers = headers.clone # don't want to modify the original variable
        parts_headers = headers.delete(:parts) || {}
        super(path, headers)
        parts = params.map do |k,v|
          case v
          when Array
            v.map {|item| Parts::Part.new(boundary, k, item, parts_headers[k]) }
          else
            Parts::Part.new(boundary, k, v, parts_headers[k])
          end
        end.flatten
        parts << Parts::EpiloguePart.new(boundary)
        ios = parts.map {|p| p.to_io }
        self.set_content_type(headers["Content-Type"] || "multipart/form-data",
                              { "boundary" => boundary })
        self.content_length = parts.inject(0) {|sum,i| sum + i.length }
        self.body_stream = CompositeReadIO.new(*ios)
      end
    end


# multipart.rb

    class Multipart < Net::HTTP::Post
      include Multipartable
    end

end