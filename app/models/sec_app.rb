require 'uuidtools'
require 'fileutils'

class SecApp < ActiveRecord::Base

  has_many :certificates, as: :certificatable
  has_many :crls, as: :crlable
  has_many :end_entities
  belongs_to :user

  before_create :generate_uuid
  after_create :create_ca_certificate, :create_client_certificate, :generate_crl
  
  def generate_uuid
    self.uuid = UUIDTools::UUID.timestamp_create.to_s
  end

  # RFC 3280
  # Need to create a recurring script that generates new CRLs periodically
  def generate_crl
    
    # Get the revoked certificates
    revoked_certificates = []
    
    end_entity_certificates.where(status: 'R').each do |cert|
      revoked_certificates << cert
    end
    
    client_certificates.where(status: 'R').each do |cert|
      revoked_certificates << cert
    end

    # Load the App's cert and key
    ca_cert = OpenSSL::X509::Certificate.new(ca_certificate.certificate)
    ca_key = OpenSSL::PKey::RSA.new self.ca_key

    # Create a new CRL object
    crl = OpenSSL::X509::CRL.new
    
    # Add the PSYPHR CA as the issuer
    crl.issuer = ca_cert.subject
    
    # Add the validity dates
    crl.last_update = Time.now
    crl.next_update = Time.now + (60*60*24*2)

    # Add the CRL extensions
    crl.add_extension(OpenSSL::X509::Extension.new("crlNumber", OpenSSL::ASN1::Integer(crl_count+1), false))
    crl.add_extension(OpenSSL::X509::Extension.new("authorityKeyIdentifier","keyid:always",false))

    # Set the CRL version
    crl.version = 1 # Specify CRL v2 (integer value: 1)

    # Add the revoked certificate serial numbers to the CRL
    revoked_certificates.each do |cert|
      
      certificate = OpenSSL::X509::Certificate.new cert.certificate
      
      revoked = OpenSSL::X509::Revoked.new
      
      revoked.serial = certificate.serial
      revoked.time = cert.revoked_at

      crl.add_revoked revoked
      
    end

    # Sign the CRL with the App's key
    crl.sign ca_key, OpenSSL::Digest::SHA1.new

    # Increment the app CRL counter
    update_attributes(crl_count: crl_count+1)

    # Create a unique folder for this app's CRL
    dirname = "#{Rails.root}/public/pki/cdp/crl/#{uuid}"
    
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    # Write the CRL to file
    File.open("#{Rails.root}/public/pki/cdp/crl/#{uuid}/subca.crl", 'wb') do |f|
      f.write crl.to_der
    end
    
  end
  
  def client_certificate
    certificates.where("status = 'V' AND distinguished_name LIKE ?", "%OU=client%").order("created_at DESC").first
  end
  
  def ca_certificate
    certificates.where("status = 'V' AND distinguished_name LIKE ?", "%OU=ca%").order("created_at DESC").first
  end
  
  def client_certificates
    certificates.where("distinguished_name LIKE ?", "%OU=client%")
  end
  
  def end_entity_certificates
    ee_ids = end_entities.map{ |entity| entity.id }
    certificates = Certificate.where("certificatable_type = 'EndEntity' AND certificatable_id IN (?)", ee_ids)
    return certificates
  end
  
  def has_client_certificate
    client_certificate != nil
  end
  
  def has_ca_certificate
    ca_certificate != nil
  end
  
  def create_ca_certificate
    
    update_attributes(ca_key: SecApp.generate_rsa_key.to_der)
    rsa_key = OpenSSL::PKey::RSA.new ca_key

    # Load the PSYPHR cert and key
    psyphr_ca_cert = OpenSSL::X509::Certificate.new File.read(APP_CONFIG[:ca_cert].to_s)
    psyphr_ca_key = OpenSSL::PKey::RSA.new File.read(APP_CONFIG[:ca_key].to_s)

    csr_cert = OpenSSL::X509::Certificate.new
    csr_cert.serial = UUIDTools::UUID.timestamp_create.hash
    csr_cert.version = 2
    csr_cert.not_before = Time.now
    csr_cert.not_after = Time.now + (60*60*24*730)

    csr_cert.subject = OpenSSL::X509::Name.parse "CN=#{uuid}/OU=ca"
    csr_cert.public_key = rsa_key
    csr_cert.issuer = psyphr_ca_cert.subject

    # Add Extensions
    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = csr_cert
    extension_factory.issuer_certificate = psyphr_ca_cert

    csr_cert.add_extension(extension_factory.create_extension("basicConstraints","CA:TRUE",true))
    csr_cert.add_extension(extension_factory.create_extension("keyUsage","keyCertSign, cRLSign", true))
    csr_cert.add_extension(extension_factory.create_extension("subjectKeyIdentifier","hash",false))
    csr_cert.add_extension(extension_factory.create_extension("authorityKeyIdentifier","keyid:always",false))

    csr_cert.sign psyphr_ca_key, OpenSSL::Digest::SHA1.new
    
    Certificate.create(certificatable_type: 'SecApp',  certificatable_id: id, certificate: csr_cert.to_der, expires_at: csr_cert.not_after, status: 'V', distinguished_name: csr_cert.subject.to_s, serial_number: csr_cert.serial.to_i)
    
  end
  
  def create_client_certificate
    
    update_attributes(client_key: SecApp.generate_rsa_key.to_der)
    rsa_key = OpenSSL::PKey::RSA.new client_key

    # Load the PSYPHR cert and key
    ca_cert = OpenSSL::X509::Certificate.new File.read(APP_CONFIG[:ca_cert].to_s)
    ca_key = OpenSSL::PKey::RSA.new File.read(APP_CONFIG[:ca_key].to_s)

    csr_cert = OpenSSL::X509::Certificate.new
    csr_cert.serial = UUIDTools::UUID.timestamp_create.hash
    csr_cert.version = 2
    csr_cert.not_before = Time.now
    csr_cert.not_after = Time.now + (60*60*24*365)

    csr_cert.subject = OpenSSL::X509::Name.parse "CN=#{uuid}/OU=client"
    csr_cert.public_key = rsa_key
    csr_cert.issuer = ca_cert.subject

    # Add Extensions
    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = csr_cert
    extension_factory.issuer_certificate = ca_cert
    
    csr_cert.add_extension    extension_factory.create_extension('basicConstraints', 'CA:FALSE')
    csr_cert.add_extension    extension_factory.create_extension(
        'keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')
    csr_cert.add_extension    extension_factory.create_extension('subjectKeyIdentifier', 'hash')

    csr_cert.sign ca_key, OpenSSL::Digest::SHA1.new

    Certificate.create(certificatable_type: 'SecApp',  certificatable_id: id, certificate: csr_cert.to_der, expires_at: csr_cert.not_after, status: 'V', distinguished_name: csr_cert.subject.to_s, serial_number: csr_cert.serial.to_i)
    
  end
  
  # Returns the CA certificates relating to all the PSYPHR apps
  def self.app_certificates
    app_ids = SecApp.all.map { |app| app.id }
    certificates = Certificate.where("certificatable_type = 'SecApp' AND certificatable_id IN (?)", app_ids)
    return certificates
  end
  
  def self.generate_rsa_key
    key = OpenSSL::PKey::RSA.new(2048)
    return key
  end
  
end
