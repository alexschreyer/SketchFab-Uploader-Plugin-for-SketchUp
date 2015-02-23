require 'net/http'
require "parts"
require "stream"

module MultiPart
  class Post
    def initialize(post_params, request_headers={})
      @parts, @streams = [], []
      construct_post_params(post_params)
      @request_headers = request_headers
    end

    def construct_post_params(post_params)
      post_params.each_pair do |key, val|
        if(val.respond_to?(:content_type)) #construct file part
          @parts << Parts::StringParam.new( "--" + multi_part_boundary + "\r\n" + \
            "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{val.file_name}\"\r\n" + \
            "Content-Type: #{val.content_type}\r\n\r\n"
          )
          @streams << val
          @parts << Parts::StreamParam.new(val, val.file_size)
        else #construct string part param
          @parts << Parts::StringParam.new("--#{multi_part_boundary}\r\n" + "Content-Disposition: form-data; name=\"#{key}\"\r\n" + "\r\n" + "#{val}\r\n")
        end
      end
      @parts << Parts::StringParam.new( "\r\n--" + multi_part_boundary + "--\r\n" )
    end

    def multi_part_boundary
      @boundary ||= '----RubyMultiPart' + rand(1000000).to_s + 'ZZZZZ'
    end

    def submit(to_url, query_string=nil)
      post_stream = Stream::MultiPart.new(@parts)
      url = URI.parse( to_url )
      post_url_with_query_string = "#{url.path}"
      post_url_with_query_string = "#{post_url_with_query_string}?#{query_string}" unless(query_string.nil?)
      req = Net::HTTP::Post.new(post_url_with_query_string, @request_headers)
      req.content_length = post_stream.size
      req.content_type = 'multipart/form-data; boundary=' + multi_part_boundary
      req.body_stream = post_stream
      http_handle = Net::HTTP.new(url.host, url.port)
      if(url.scheme == "https") then
          http_handle.use_ssl = true
          http_handle.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      res = http_handle.start {|http| http.request(req)}

      #close all the open hooks to the file on file-system
      @streams.each do |local_stream|
        local_stream.close();
      end
      res
    end
  end
end
