require 'openssl'
class Admin::SecAppsController < ApplicationController
  
    before_filter :require_user
    before_filter :require_app, except: [:index, :new, :create]

    def index
      @apps = @current_user.sec_apps
    end

    def new
      @app = SecApp.new
    end

    def create
      
      @app = SecApp.new(sec_app_params)
      
      unless @current_user.sec_apps.where(name: params[:sec_app][:name]).first
      
        @app.user_id = @current_user.id

        if @app.save
          redirect_to :admin_apps
        else
          
          render :new, alert: 'Couldn\'t create the app'
        
        end
        
      else
        
        
        render :new, alert: 'App names need to be unique'
      
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

      @entity_count = @app.end_entities.count

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
      cert = OpenSSL::X509::Certificate.new(@app.client_certificate.certificate)
      p12 = OpenSSL::PKCS12.create("passwd", "Cloud Sec Client Certificate", key, cert)
      send_data cert.to_der, type: 'application/x-pkcs12', filename: 'client-archive.p12', disposition: 'attachment'
    end

    def ca_cert_der
      cert = OpenSSL::X509::Certificate.new(@app.ca_certificate.certificate)
      send_data cert.to_der, type: 'application/x-x509-ca-cert', filename: 'ca-cert.der', disposition: 'attachment'
    end

    def ca_cert_pem
      cert = OpenSSL::X509::Certificate.new(@app.ca_certificate.certificate)
      send_data cert.to_pem, type: 'application/x-pem-file', filename: 'ca-cert.pem', disposition: 'attachment'
    end

    # Generate a new CRL on demand
    def generate_crl

      @app.generate_crl

      redirect_to admin_app_path(@app)

    end

    # Need to move this out to a recurring script so it's not generated on the fly each time
    def download_arl
      
      revoked_certificates = []
      
      SecApp.app_certificates.where(status: 'R').each do |cert|
        revoked_certificates << cert
      end
      
      # Load the server CA cert
      ca_cert = OpenSSL::X509::Certificate.new File.read(APP_CONFIG[:ca_cert].to_s)

      # Sign it with the server CA key
      ca_key = OpenSSL::PKey::RSA.new File.read(APP_CONFIG[:ca_key].to_s)
      

      crl = OpenSSL::X509::CRL.new
      crl.issuer = ca_cert.subject
      crl.last_update = Time.now
      crl.next_update = Time.now + (60*60*24*60)

      crl.add_extension(OpenSSL::X509::Extension.new("crlNumber", OpenSSL::ASN1::Integer(1), false))
      crl.add_extension(OpenSSL::X509::Extension.new("authorityKeyIdentifier","keyid:always",false))

      crl.version = 1 # Specify CRL v2 (integer value: 1)

      # app.update_attributes()

      revoked_certificates.each do |cert|
        
        certificate = OpenSSL::X509::Certificate.new cert.certificate
        
        revoked = OpenSSL::X509::Revoked.new
        
        revoked.serial = certificate.serial
        revoked.time = cert.revoked_at

        crl.add_revoked revoked
        
      end

      crl.sign ca_key, OpenSSL::Digest::SHA1.new

      send_data crl.to_der, type: 'application/x-pkcs7-crl', filename: 'psyphr-arl.crl', disposition: 'attachment'
      
    end

  private

    def require_app
      if params[:app_id]
        @app = SecApp.find(params[:app_id])
      else
        @app = SecApp.find(params[:id])
      end
    end

    def sec_app_params
      params.require(:sec_app).permit(:user_id, :name)
    end
  
end
