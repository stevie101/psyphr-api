require 'uuidtools'
# require 'rejbca'
class Admin::EndEntitiesController < ApplicationController

  before_filter :require_user
  before_filter :require_end_entity, except: [:index, :new, :create]

  def index
    
    @end_entities = @current_user.end_entities
    
  end
  
  def new
    
    @apps = @current_user.apps
    @end_entity = EndEntity.new
    
  end
  
  def create
    
    @end_entity = EndEntity.new(end_entity_params)
    
    @app = current_user.apps.find(params[:app][:id])
    
    @end_entity.app_id = @app.id

    if @end_entity.save
      
      # rejbca = Rejbca.instance
      
      # user_attributes = { 'username' => @end_entity.uuid, 'password' => @end_entity.e_password, 'subjectDN' => "CN=#{@end_entity.uuid},OU=#{@app.name},OU=Cloud Sec,L=London,C=GB" }
      # result = rejbca.add_user(user_attributes)
      

      
      redirect_to :admin_end_entities
    else
      render :new
    end
    
  end
  
  def edit
    
  end

  def update
    
  end

  def destroy
    
  end
  
  def show
    
    @end_entity = @current_user.end_entities.find(params[:id])
    
    @certificates = @end_entity.certificates
    
    @current_cert = @end_entity.certificates.where(status: 'V').first
    
    if @current_cert
      @cert = OpenSSL::X509::Certificate.new(@current_cert.certificate)
      @not_after = @cert.not_after
    end
    
  rescue
    render text: 'End entity not found'
  end

  def enrol
    
    # TODO - Perform CSR attribute check before enrolling
    
    @end_entity = @current_user.end_entities.find(params[:end_entity_id])
    @app = current_user.apps.find(@end_entity.app_id)
    
    # rejbca = Rejbca.instance
    
    # user_attribs = { 'username' => @end_entity.uuid, 'password' => @end_entity.e_password , 'subjectDN' => "CN=#{@end_entity.uuid},OU=#{@app.name},OU=Cloud Sec,L=London,C=GB" }
    # certificate = rejbca.enrol(user_attribs, params[:csr])
    
    csr = OpenSSL::X509::Request.new params[:csr]
    
    raise 'CSR can not be verified' unless csr.verify csr.public_key
    
    # Load the CA cert for this app
    ca_cert = OpenSSL::X509::Certificate.new @app.ca_cert
    # Sign it with the CA key for this app
    ca_key = OpenSSL::PKey::EC.new @app.ca_key
    
    # Create the certificate
    csr_cert = OpenSSL::X509::Certificate.new
    csr_cert.serial = UUIDTools::UUID.timestamp_create.hash
    csr_cert.version = 2
    csr_cert.not_before = Time.now
    csr_cert.not_after = Time.now + (60*60*24*365)    # Validity 1 year from now

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

    csr_cert.sign ca_key, OpenSSL::Digest::SHA1.new
    
    certificate = Certificate.new(certificate: csr_cert.to_der, expires_at: csr_cert.not_after, status: 'V', distinguished_name: csr_cert.subject.to_s, serial_number: csr_cert.serial)
    @end_entity.certificates << certificate
    @end_entity.update_attributes( status: 2 )
    
    redirect_to admin_end_entity_url(@end_entity)
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

  def require_end_entity
    if params[:end_entity_id]
      @end_entity = EndEntity.find(params[:end_entity_id])
    else
      @end_entity = EndEntity.find(params[:id])
    end
  end

  def end_entity_params
    params.require(:end_entity).permit(:app_id, :did)
  end

end
