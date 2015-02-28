#!/usr/bin/env ruby

require 'openssl'
require 'faraday'
require 'base64'

@app_uuid = '9b33a672-be9b-11e4-b911-0800274c20f7'

#puts File.expand_path(File.dirname(__FILE__)) + '/server-cert.pem'

ssl_options = {
  client_cert: OpenSSL::X509::Certificate.new(File.read('./client.crt')),
  client_key:  OpenSSL::PKey::RSA.new(File.read('./client.key'), nil),
  ca_file: File.expand_path(File.dirname(__FILE__)) + '/ca.crt',
  version: :TLSv1_2
}
conn = Faraday.new(url: 'https://api.cloudsec.com', ssl: ssl_options) do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.response :logger                  # log requests to STDOUT
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

response = conn.get "/.well-known/est/#{@app_uuid}/cacerts"     # GET

pkcs7 = OpenSSL::PKCS7.new Base64.decode64 response.body

response = conn.post "/api/end_entities/", { end_entity: { sec_app_id: @app_uuid, did: 'new entity' } }

puts response.body




