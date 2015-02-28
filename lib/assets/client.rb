#!/usr/bin/env ruby

require 'openssl'
require 'faraday'

# @uuid = 

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

response = conn.get '/.well-known/est/:uuid/cacerts'     # GET
puts response.body




