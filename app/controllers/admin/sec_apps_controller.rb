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

    # The client cert is signed by the psyphr CA cert
    # So the revoked serial number should appear on the global psyphr CRL
    def revoke_client_cert
      
      @app.revoke_client_cert
        
      redirect_to admin_app_path(@app)

    end

    def revoke_ca_cert
      
      @app.revoke_ca_cert
      @app.generate_arl
      
      redirect_to admin_app_path(@app)
      
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
    
    def rekey_ca_cert
      
      @app.create_ca_certificate
      
      redirect_to admin_app_path(@app)
      
    end

    def rekey_client_cert
      
      @app.create_client_certificate
      
      redirect_to admin_app_path(@app)
      
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
