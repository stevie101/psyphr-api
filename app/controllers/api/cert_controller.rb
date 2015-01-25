require 'openssl'
class Api::CertController < ApplicationController
  
  @@file = "#{Rails.root}/lib/assets/MedhistoryServer.pem"
  
  # Sends the certificate in PEM format
  def show
    send_file @@file
  end
  
  # Outputs the SHA1 fingerprint of the certificate
  def fingerprint
    digest = Digest::SHA1.file(@@file).hexdigest
    render text: digest
  end
  
end
