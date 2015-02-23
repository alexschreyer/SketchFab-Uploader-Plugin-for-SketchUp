
$: << File.dirname(__FILE__)

require 'uri'
require 'net/http'
require 'net/https'
require 'openssl'
require 'ruby-multipart-post-as'

begin

    # Compile data
    data = {
              'token' => '1dcbb69b5ea248bb8729eef992ce7ab4',
              'fileModel' => AS_SketchfabUploader::UploadIO.new(File.join(File.dirname(__FILE__),'temp_export.zip'), "application/zip"),
              'title' => 'Test',
              'description' => '',
              'tags' => '',
              'private' => true,
              'password' => '',
              'source' => 'sketchup-exporter'
    }

    url = 'https://api.sketchfab.com/v1/models'

    # Submission URL
    uri = URI.parse(url)

    # Prepare data for submission
    req = AS_SketchfabUploader::Multipart.new uri.path, data

    p req.body_stream.inspect

    # Submit via SSL
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = https.start { |cnt| cnt.request(req) }

    p res.body

rescue Exception => e

    p e

end
