require 'yaml/store'

class Psyphr

  def self.generate_crl
    
    # The psyphr CRL contains any EE cert serials that have been signed with the psyphr subca or root key
    # This includes User app client cert serial numbers
    
  end

  def self.generate_arl
  
    # The psyphr ARL contains any app CA cert serial numbers along with any psyphr CA cert serial numbers
  
    store = YAML::Store.new "#{Rails.root}/config/settings.yml"
  
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

    arl_count = 0

    store.transaction do
    
      arl_count = store[:arl_count]
      
    end

    crl.add_extension(OpenSSL::X509::Extension.new("crlNumber", OpenSSL::ASN1::Integer(arl_count+1), false))
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

    store.transaction do
    
      store[:arl_count] = arl_count+1
    
    end

    # Create a unique folder for this app's CRL
    dirname = "#{Rails.root}/public/pki/cdp/arl"

    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    # Write the CRL to file
    File.open("#{Rails.root}/public/pki/cdp/arl/psyphrArl.crl", 'wb') do |f|
      f.write crl.to_der
    end
  
  end

end