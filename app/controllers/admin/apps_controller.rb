require 'openssl'
class Admin::AppsController < ApplicationController
  
  before_filter :require_user
  
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
      
      # Generate a CSR
      key = OpenSSL::PKey::EC.new("prime256v1")
      key.generate_key

      csr = OpenSSL::X509::Request.new
      csr.version = 1
      csr.subject = OpenSSL::X509::Name.parse "CN=#{@app.uuid}/DC=example"
      csr.public_key = key
      csr.sign key, OpenSSL::Digest::SHA256.new
      csr.to_pem
      
      # Verify the csr against the included public key
      # Should always pass in this instance as created above
      raise 'CSR can not be verified' unless csr.verify csr.public_key
      
      # Load the CA cert
      ca_cert = OpenSSL::X509::Certificate.new File.read "#{Rails.root}/lib/assets/server-cert.pem"
      
      # Sign it with the server CA key
      
      ca_key = OpenSSL::PKey::EC.new File.read "#{Rails.root}/lib/assets/server-key.pem"
      
      csr_cert = OpenSSL::X509::Certificate.new
      csr_cert.serial = 0
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
      
      puts "121212212"
      puts csr_cert.to_pem
      puts "121212212"
      
      p12 = OpenSSL::PKCS12.create("passwd", "Cloud Sec Client Certificate", key, csr_cert)
      
      File.open("#{Rails.root}/lib/assets/pkcs12.p12", "wb+") do |f|
        f.write p12.to_der
      end
      
      #open "#{Rails.root}/lib/assets/pkcs12.p12", 'w' do |io| io.write p12.to_der end
      
      redirect_to :admin_apps
    else
      render :new
    end
  end
  
  def show
    @app = App.find(params[:id])
  end
  
  def app_params
    params.require(:app).permit(:user_id, :name)
  end
end
