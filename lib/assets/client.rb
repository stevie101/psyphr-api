#!/usr/bin/env ruby

require 'openssl'
require 'faraday'
require 'base64'
require 'json'

@app_uuid = '9b33a672-be9b-11e4-b911-0800274c20f7'

@renewal = 50      # Renewal Percentage

def init
  
  ssl_options = {
    client_cert: OpenSSL::X509::Certificate.new(File.read('./client.crt')),
    client_key:  OpenSSL::PKey::RSA.new(File.read('./client.key'), nil),
    ca_file: File.expand_path(File.dirname(__FILE__)) + '/ca.crt',
    version: :TLSv1_2
  }
  @conn = Faraday.new(url: 'https://api.cloudsec.com', ssl: ssl_options) do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.response :logger                  # log requests to STDOUT
    faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
  end

  # Get the CA certs
  response = @conn.get "/.well-known/est/#{@app_uuid}/cacerts"     # GET

  pkcs7 = OpenSSL::PKCS7.new Base64.decode64 response.body

  # Write CA certs pkcs7 to file
  File.open("cacerts.p7", "w") do |f|
      f.write pkcs7.to_pem
  end

  # Create a new entity
  @entity_did = 'another new entity9'
  response = @conn.post "/api/end_entities/", { end_entity: { sec_app_id: @app_uuid, did: @entity_did } }   # POST

  result = JSON.parse(response.body)

  @entity_uuid = result['uuid']

end

# Enrol the new entity
def enroll

  @key = OpenSSL::PKey::RSA.new(2048)

  # Write cert to file
  File.open("ee.key", "w") do |f|
      f.write @key.to_pem
  end

  csr = OpenSSL::X509::Request.new
  csr.version = 1

  subject = "/C=GB/L=London/O=Acme Ltd/OU=Cloud Sec/OU=EE/OU=Test/OU=#{@entity_uuid}/CN=#{@entity_did}"

  csr.subject = OpenSSL::X509::Name.parse subject
  csr.public_key = @key
  csr.sign @key, OpenSSL::Digest::SHA1.new

  message = Base64.encode64 csr.to_pem

  response = @conn.post "/.well-known/est/#{@app_uuid}/simpleenroll", message  #POST

  @pkcs7 = OpenSSL::PKCS7.new Base64.decode64 response.body

  @cert = OpenSSL::X509::Certificate.new @pkcs7.certificates.first

  puts @cert.to_pem
  
  # Write cert to file
  File.open("ee.crt", "w") do |f|
      f.write @cert.to_pem
  end
  
end

# Re-Enroll the entity
def reenroll

  csr = OpenSSL::X509::Request.new
  csr.version = 1
  csr.subject = @cert.subject
  csr.public_key = @cert.public_key
  csr.sign @key, OpenSSL::Digest::SHA1.new

  message = Base64.encode64 csr.to_pem

  response = @conn.post "/.well-known/est/#{@app_uuid}/simplereenroll", message  #POST

  @pkcs7 = OpenSSL::PKCS7.new Base64.decode64 response.body

  @cert = OpenSSL::X509::Certificate.new @pkcs7.certificates.first

  puts @cert.to_pem
  
end
 
init()
enroll()
reenroll()
