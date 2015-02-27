require 'openssl'
class Admin::AppsController < ApplicationController
  
  before_filter :require_user
  before_filter :require_app, except: [:index, :new, :create]
  
  def index
    @apps = @current_user.apps
  end
  
  def new
    @app = App.new
  end
  
  def create
    @app = App.new(app_params)
    @app.user_id = @current_user.id
    
    if @app.save
      
      # Create a client certificate for this app
      
      # Generate a client key for app
      client_key = generate_rsa_key
      # Create client cert for app
      client_cert = create_client_cert_for_app_and_key(@app, client_key)
      
      # Create certificate model and associate with the app
      certificate = Certificate.new(certificate: client_cert.to_der, expires_at: client_cert.not_after, status: 'V', distinguished_name: client_cert.subject.to_s, serial_number: client_cert.serial)
      @app.certificates << certificate
      
      # Update app with the Client Key
      @app.update_attribute( :client_key, client_key.to_der)
      
      # Create a ca certificate for this app
      
      # Generate a ca key for app
      ca_key = generate_rsa_key
      # Create ca cert for app
      ca_cert = create_ca_cert_for_app_and_key(@app, ca_key)
      
      # Create CA certificate model and associate with the app
      certificate = Certificate.new(certificate: ca_cert.to_der, expires_at: ca_cert.not_after, status: 'V', distinguished_name: ca_cert.subject.to_s, serial_number: ca_cert.serial)
      @app.certificates << certificate
      
      # Update app with the CA Key
      @app.update_attribute( :ca_key, ca_key.to_der)     
      
      # p12 = OpenSSL::PKCS12.create("passwd", "Cloud Sec Client Certificate", key, csr_cert)
      # File.open("#{Rails.root}/lib/assets/pkcs12.p12", "wb+") do |f|
      #   f.write p12.to_der
      # end
      
      #open "#{Rails.root}/lib/assets/pkcs12.p12", 'w' do |io| io.write p12.to_der end
      
      redirect_to :admin_apps
    else
      render :new
    end
  end
  
  def show 
    
    @cert, @ca_cert, @not_after, @ca_not_after = nil
    
    if @app.has_client_certificate
      @cert = OpenSSL::X509::Certificate.new(@app.client_certificate.certificate)
      @not_after = @cert.not_after
    end
    
    if @app.has_ca_certificate
      @ca_cert = OpenSSL::X509::Certificate.new(@app.ca_certificate.certificate)
      @ca_not_after = @ca_cert.not_after
    end
    
  end
  
  def revoke
    
  end
  
  def client_key_der
    key = OpenSSL::PKey::RSA.new(@app.client_key)
    send_data key.to_der, type: 'application/pkcs8', filename: 'client-key.der', disposition: 'attachment'
  end
  
  def client_key_pem
    key = OpenSSL::PKey::RSA.new(@app.client_key)
    send_data key.to_pem, type: 'application/x-pem-file', filename: 'client-key.pem', disposition: 'attachment'
  end
  
  def client_cert_der
    cert = OpenSSL::X509::Certificate.new(@app.client_certificate.certificate)
    send_data cert.to_der, type: 'application/x-x509-user-cert', filename: 'client-cert.der', disposition: 'attachment'
  end
  
  def client_cert_pem
    cert = OpenSSL::X509::Certificate.new(@app.client_certificate.certificate)
    send_data cert.to_pem, type: 'application/x-pem-file', filename: 'client-cert.pem', disposition: 'attachment'
  end
  
  def client_pkcs12_der
    key = OpenSSL::PKey::RSA.new(@app.client_key)
    cert = OpenSSL::X509::Certificate.new(@app.client_cert)
    p12 = OpenSSL::PKCS12.create("passwd", "Cloud Sec Client Certificate", key, cert)
    send_data cert.to_der, type: 'application/x-pkcs12', filename: 'client-archive.p12', disposition: 'attachment'
  end
  
  def ca_cert_der
    cert = OpenSSL::X509::Certificate.new(@app.ca_cert)
    send_data cert.to_der, type: 'application/x-x509-ca-cert', filename: 'ca-cert.der', disposition: 'attachment'
  end
  
  def ca_cert_pem
    cert = OpenSSL::X509::Certificate.new(@app.ca_cert)
    send_data cert.to_pem, type: 'application/x-pem-file', filename: 'ca-cert.pem', disposition: 'attachment'
  end
  
  
  # RFC 3280
  def download_crl
    
    ca_cert = OpenSSL::X509::Certificate.new(@app.ca_certificate.certificate)
    ca_key = OpenSSL::PKey::EC.new @app.ca_key
    
    crl = OpenSSL::X509::CRL.new
    crl.issuer = ca_cert.subject
    crl.last_update = Time.now
    crl.next_update = Time.now + (60*60*24*2)
    
    crl.add_extension(OpenSSL::X509::Extension.new("crlNumber", OpenSSL::ASN1::Integer(1), false))
    crl.add_extension(OpenSSL::X509::Extension.new("authorityKeyIdentifier","keyid:always",false))
    
    crl.version = 1 # Specify CRL v2 (integer value: 1)
    
    # app.update_attributes()
    
    
    revoked = OpenSSL::X509::Revoked.new
    revoked.serial = 191125413
    revoked.time = Time.now
    
    crl.add_revoked revoked
    
    crl.sign ca_key, OpenSSL::Digest::SHA1.new
    
    puts crl.to_pem
    
    render text: 'crl' and return
    
  end
  
private
  
  def require_app
    if params[:app_id]
      @app = App.find(params[:app_id])
    else
      @app = App.find(params[:id])
    end
  end
  
  def app_params
    params.require(:app).permit(:user_id, :name)
  end
  
  # def generate_ec_key
  #   key = OpenSSL::PKey::EC.new("prime256v1")
  #   key.generate_key
  #   return key
  # end
  
  def generate_rsa_key
    key = OpenSSL::PKey::RSA.new(2048)
    return key
  end
  
  def generate_csr_with_subject_and_key(subject, key)
    csr = OpenSSL::X509::Request.new
    csr.version = 1
    csr.subject = OpenSSL::X509::Name.parse subject
    csr.public_key = key
    csr.sign key, OpenSSL::Digest::SHA256.new
    return csr
  end
  
  def create_ca_cert_for_app_and_key(app, key)
    csr = generate_csr_with_subject_and_key("CN=#{@app.uuid}/OU=ca", key)
    
    # Verify the csr against the included public key
    # Should always pass in this instance as created above
    raise 'CSR can not be verified' unless csr.verify csr.public_key
    
    # Load the server CA cert
    ca_cert = OpenSSL::X509::Certificate.new File.read(APP_CONFIG[:ca_cert].to_s)
    
    # Sign it with the server CA key
    ca_key = OpenSSL::PKey::RSA.new File.read(APP_CONFIG[:ca_key].to_s)
    
    csr_cert = OpenSSL::X509::Certificate.new
    csr_cert.serial = UUIDTools::UUID.timestamp_create.hash
    csr_cert.version = 2
    csr_cert.not_before = Time.now
    csr_cert.not_after = Time.now + (60*60*24*730)

    csr_cert.subject = csr.subject
    csr_cert.public_key = csr.public_key
    csr_cert.issuer = ca_cert.subject

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = csr_cert
    extension_factory.issuer_certificate = ca_cert

    csr_cert.add_extension(extension_factory.create_extension("basicConstraints","CA:TRUE",true))
    csr_cert.add_extension(extension_factory.create_extension("keyUsage","keyCertSign, cRLSign", true))
    csr_cert.add_extension(extension_factory.create_extension("subjectKeyIdentifier","hash",false))
    csr_cert.add_extension(extension_factory.create_extension("authorityKeyIdentifier","keyid:always",false))

    csr_cert.sign ca_key, OpenSSL::Digest::SHA1.new
    return csr_cert
  end
  
  def create_client_cert_for_app_and_key(app, key)
    csr = generate_csr_with_subject_and_key("CN=#{@app.uuid}/OU=client", key)
    
    # Verify the csr against the included public key
    # Should always pass in this instance as created above
    raise 'CSR can not be verified' unless csr.verify csr.public_key
    
    # Load the CA cert
    puts "---|"
    puts APP_CONFIG[:ca_cert]
    puts "|---"
    
    ca_cert = OpenSSL::X509::Certificate.new File.read(APP_CONFIG[:ca_cert].to_s)
    
    # Sign it with the server CA key
    
    ca_key = OpenSSL::PKey::RSA.new File.read(APP_CONFIG[:ca_key].to_s)
    
    csr_cert = OpenSSL::X509::Certificate.new
    csr_cert.serial = UUIDTools::UUID.timestamp_create.hash
    csr_cert.version = 2
    csr_cert.not_before = Time.now
    csr_cert.not_after = Time.now + (60*60*24*365)

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
    return csr_cert
  end
  
end
