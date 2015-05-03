require 'base64'
class Api::EndEntities::CertificatesController < ApplicationController
  
  before_filter :require_app, :require_entity
  
  # DELETE
  # Revoke End Entity Certificate matching a valid app UUID, end_entity UUID and certificate serial number
  def revoke
    
  end
  
  # GET
  # End Entity Certificate matching a valid app UUID and end_entity UUID
  def show
    
    # curl -X GET -4 -H "Content-Type: application/json" -d '{"sec_app_id" : "< app_sec_uuid >"}'  http://localhost:3000/api/end_entities/< end_entity_uuid >/certificate
    
    # Set Response headers
    headers['Content-Type'] = "application/pkcs7-mime"
    headers['Content-Transfer-Encoding'] = "base64"
    
      
    @cert = @end_entity.certificates.where(status: 'V').order('expires_at DESC').first
    
    if @cert
      
      certificate = OpenSSL::X509::Certificate.new(@cert.certificate)
      
      pkcs7 = OpenSSL::PKCS7.new
      pkcs7.type = 'signed'
      pkcs7.certificates = [certificate]

      render text: Base64.encode64(pkcs7.to_pem), status: 200 and return
      
      
      render json: {certificate: @end_entity.cert} and return
      
    else
    
      render json: {error: true, message: 'No valid cert found'} and return
    
    end
    
  end
  
  # Outputs the SHA1 fingerprint of the certificate in der format
  def fingerprint
    
    @cert = @end_entity.certificates.where(status: 'V').order('expires_at DESC').first
    
    if @cert
      
      certificate = OpenSSL::X509::Certificate.new(@cert.certificate)
      
      digest = Digest::SHA1.hexdigest certificate.to_pem
      render text: digest, status: 200 and return
      
    else
    
      render json: {error: true, message: 'No valid cert found'} and return
    
    end

  end
  
  def require_entity
    
    @end_entity = @app.end_entities.find_by_uuid(params[:end_entity_id])
    
    unless @end_entity
    
      render json: {error: true, message: 'Invalid entity'} and return
    
    end
    
  end
  
  def require_app
    
    @app = SecApp.find_by_uuid(params[:end_entity][:sec_app_id])
    
    unless @app
    
      render json: {error: true, message: 'Invalid app'} and return
    
    end
    
  end
  
end
