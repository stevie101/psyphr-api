require 'open-uri'
require 'base64'
class Api::Devices::CertController < ApplicationController
  
  # Sends the certificate for this device in PEM format
  def show
    device = Device.find(params[:id])
    send_file device.cert
  end
  
  # Outputs the SHA1 fingerprint of the certificate
  def fingerprint
    device = Device.find(params[:id])
    digest = Digest::SHA1.file(device.cert).hexdigest
    render text: digest
  end  
  
  # Save device certificate (in PEM format)
  def create
    device = Device.find(params[:id])
    data = URI::decode(params[:data])
    cert = Base64.decode(data)
    device.cert = cert
    if device.save
      render json: {result: 'success'} and return
    else
      render json: {result: 'error'} and return
    end
  end
  
end
