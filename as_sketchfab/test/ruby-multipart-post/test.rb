
$: << File.dirname(__FILE__)

require 'uri'
require 'net/http'
require 'net/https'
require 'base64'
require 'openssl'
require 'ruby-multipart-post-as'

begin

    # Compile data
    data = {
              'token' => '1dcbb69b5ea248bb8729eef992ce7ab4',
              'fileModel' => FileUploadIO.new(File.join(File.dirname(__FILE__),'temp_export.zip'), "application/zip"),
              'title' => 'Test',
              'description' => '',
              'tags' => '',
              'private' => true,
              'password' => '',
              'source' => 'sketchup-exporter'
    }

    url = 'https://api.sketchfab.com/v1/models'

    multipart_post = MultiPart::Post.new(data)

    p multipart_post

    res = multipart_post.submit(url)

    p res

rescue Exception => e

    p e

end
