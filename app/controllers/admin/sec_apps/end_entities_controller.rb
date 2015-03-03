class Admin::SecApps::EndEntitiesController < ApplicationController
  
  before_filter :require_user
  before_filter :require_app
  before_filter :require_end_entity, except: [:index, :new, :create]
  
  def index
    @entities = @app.end_entities
  end
  
  def new
    
    @apps = @current_user.sec_apps
    @end_entity = EndEntity.new
    
  end
  
  def create
    
    @end_entity = EndEntity.new(end_entity_params)
    
    @end_entity.sec_app_id = @app.id

    if @end_entity.save
      
      redirect_to admin_app_end_entities_path(@app)
    else
      render :new
    end
    
  end
  
  def show

    @certificates = @end_entity.certificates.order("created_at DESC")

  rescue
    render text: 'End entity not found'
  end
  
  def enrol
    
    # TODO - Perform CSR attribute check before enrolling
    
    @end_entity = @app.end_entities.find(params[:end_entity_id])
    
    # rejbca = Rejbca.instance
    
    # user_attribs = { 'username' => @end_entity.uuid, 'password' => @end_entity.e_password , 'subjectDN' => "CN=#{@end_entity.uuid},OU=#{@app.name},OU=Cloud Sec,L=London,C=GB" }
    # certificate = rejbca.enrol(user_attribs, params[:csr])
    
    csr = OpenSSL::X509::Request.new params[:csr]
    
    raise 'CSR can not be verified' unless csr.verify csr.public_key
    
    # Load the CA cert for this app
    ca_cert = OpenSSL::X509::Certificate.new @app.ca_certificate.certificate
    # Sign it with the CA key for this app
    ca_key = OpenSSL::PKey::RSA.new @app.ca_key
    
    # Create the certificate
    csr_cert = OpenSSL::X509::Certificate.new
    csr_cert.serial = UUIDTools::UUID.timestamp_create.hash
    csr_cert.version = 2
    csr_cert.not_before = Time.now
    csr_cert.not_after = Time.now + (60*60*24*365)    # Validity 1 year from now
    # csr_cert.not_after = Time.now + (60*10)    # Validity 10 minutes from now

    csr_cert.subject = csr.subject
    csr_cert.public_key = csr.public_key
    csr_cert.issuer = ca_cert.subject

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = csr_cert
    extension_factory.issuer_certificate = ca_cert

    csr_cert.add_extension    extension_factory.create_extension('basicConstraints', 'CA:FALSE')

    csr_cert.add_extension    extension_factory.create_extension(
        'keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')

    csr_cert.add_extension    extension_factory.create_extension('subjectKeyIdentifier', 'hash')

    csr_cert.add_extension    extension_factory.create_extension('crlDistributionPoints', "URI:https://cloudsec.com/apps/#{@app.uuid}/subca.crl ")

    csr_cert.sign ca_key, OpenSSL::Digest::SHA1.new
    
    certificate = Certificate.new(certificate: csr_cert.to_der, expires_at: csr_cert.not_after, status: 'V', distinguished_name: csr_cert.subject.to_s, serial_number: csr_cert.serial.to_i)
    @end_entity.certificates << certificate
    @end_entity.update_attributes( status: 2 )
    
    redirect_to admin_app_end_entity_url(@app, @end_entity)
  end
  
  # Renew generates a new certificate with the existing public key
  def renew
    
    @cert = @end_entity.certificates.where(status: 'V').order("expires_at DESC").first
    
    if @cert
      
      certificate = OpenSSL::X509::Certificate.new(@cert.certificate)
      
      # New certificate uses the same subject, public key, signature algorithm and extensions
        
      # Load the CA cert for this app
      ca_cert = OpenSSL::X509::Certificate.new @app.ca_certificate.certificate
      # Sign it with the CA key for this app
      ca_key = OpenSSL::PKey::RSA.new @app.ca_key

      # Create the certificate
      csr_cert = OpenSSL::X509::Certificate.new
      csr_cert.serial = UUIDTools::UUID.timestamp_create.hash
      csr_cert.version = 2
      csr_cert.not_before = Time.now
      csr_cert.not_after = Time.now + (60*60*24*365)    # Validity 1 year from now
      # csr_cert.not_after = Time.now + (60*10)    # Validity 10 minutes from now

      csr_cert.subject = certificate.subject
      csr_cert.public_key = certificate.public_key
      csr_cert.issuer = ca_cert.subject

      extension_factory = OpenSSL::X509::ExtensionFactory.new
      extension_factory.subject_certificate = csr_cert
      extension_factory.issuer_certificate = ca_cert

      csr_cert.add_extension    extension_factory.create_extension('basicConstraints', 'CA:FALSE')

      csr_cert.add_extension    extension_factory.create_extension(
          'keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')

      csr_cert.add_extension    extension_factory.create_extension('subjectKeyIdentifier', 'hash')

      csr_cert.add_extension    extension_factory.create_extension('crlDistributionPoints', "URI:https://cloudsec.com/apps/#{@app.uuid}/subca.crl ")

      csr_cert.sign ca_key, OpenSSL::Digest::SHA1.new

      certificate = Certificate.new(certificate: csr_cert.to_der, expires_at: csr_cert.not_after, status: 'V', distinguished_name: csr_cert.subject.to_s, serial_number: csr_cert.serial.to_i)
      @end_entity.certificates << certificate    
      
      redirect_to admin_app_end_entity_path(@app, @end_entity) and return
      
    else
    
      # Couldn't locate a existing valid cert to renew
      redirect_to admin_app_end_entity_path(@app, @end_entity), alert: 'No valid certs available' and return
    
    end
    
  end
  
  # ReKey generates a new certificate with new public key
  def rekey
    
    # The responsibility and decision to revoke certificates relating to the old key is left to the user
    
    # TODO - Perform CSR attribute check before enrolling
    
    @end_entity = @app.end_entities.find(params[:end_entity_id])
    @app = current_user.sec_apps.find(@end_entity.sec_app_id)
    
    csr = OpenSSL::X509::Request.new params[:csr]
    
    raise 'CSR can not be verified' unless csr.verify csr.public_key
    
    # Load the CA cert for this app
    ca_cert = OpenSSL::X509::Certificate.new @app.ca_certificate.certificate
    # Sign it with the CA key for this app
    ca_key = OpenSSL::PKey::RSA.new @app.ca_key
    
    # Create the certificate
    csr_cert = OpenSSL::X509::Certificate.new
    csr_cert.serial = UUIDTools::UUID.timestamp_create.hash
    csr_cert.version = 2
    csr_cert.not_before = Time.now
    csr_cert.not_after = Time.now + (60*60*24*365)    # Validity 1 year from now
    # csr_cert.not_after = Time.now + (60*10)    # Validity 10 minutes from now

    csr_cert.subject = csr.subject
    csr_cert.public_key = csr.public_key
    csr_cert.issuer = ca_cert.subject

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = csr_cert
    extension_factory.issuer_certificate = ca_cert

    csr_cert.add_extension    extension_factory.create_extension('basicConstraints', 'CA:FALSE')

    csr_cert.add_extension    extension_factory.create_extension(
        'keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')

    csr_cert.add_extension    extension_factory.create_extension('subjectKeyIdentifier', 'hash')

    csr_cert.add_extension    extension_factory.create_extension('crlDistributionPoints', "URI:https://cloudsec.com/apps/#{@app.uuid}/subca.crl ")

    csr_cert.sign ca_key, OpenSSL::Digest::SHA1.new
    
    certificate = Certificate.new(certificate: csr_cert.to_der, expires_at: csr_cert.not_after, status: 'V', distinguished_name: csr_cert.subject.to_s, serial_number: csr_cert.serial.to_i)
    @end_entity.certificates << certificate
    
    redirect_to admin_app_end_entity_path(@app, @end_entity) and return
    
  end
  
  def cert_der
    current_cert = @end_entity.certificates.where(status: 'V').first
    cert = OpenSSL::X509::Certificate.new(current_cert.certificate)
    send_data cert.to_der, type: 'application/x-x509-user-cert', filename: 'cert.der', disposition: 'attachment'
  rescue
    render text: 'End entity not found'
  end
  
  def cert_pem
    current_cert = @end_entity.certificates.where(status: 'V').first
    cert = OpenSSL::X509::Certificate.new(current_cert.certificate)
    send_data cert.to_pem, type: 'application/x-pem-file', filename: 'cert.pem', disposition: 'attachment'
  rescue
    render text: 'End entity not found'
  end
  
  private
  
  def require_app
    if params[:app_id]
      @app = SecApp.find(params[:app_id])
    else
      @app = SecApp.find(params[:id])
    end
  end
  
  def require_end_entity
    if params[:end_entity_id]
      @end_entity = EndEntity.find(params[:end_entity_id])
    else
      @end_entity = EndEntity.find(params[:id])
    end
  end
  
  def end_entity_params
    params.require(:end_entity).permit(:sec_app_id, :did)
  end
  
end
