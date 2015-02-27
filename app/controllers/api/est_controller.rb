require 'openssl'
require 'base64'
class Api::EstController < ApplicationController
  
  # GET
  # Reply with a certs-only CMC Simple PKI Response, as defined in [RFC5272]
  # MUST include the current ROOT CA cert
  # MUST include any further certs that allow for a full chain of trust to the ROOT CA
  # SHOULD include the three "ROOT CA Key Update" certificates: OldWithOld, OldWithNew and NewWithOld in the response chain (Section 4.4 of CMP [RFC4210])
  
  def cacerts
    
    # Set Response headers
    headers['Content-Type'] = "application/pkcs7-mime"
    headers['Content-Transfer-Encoding'] = "base64"
    
    # Load the CloudSec ROOT CA cert
    ca_cert = OpenSSL::X509::Certificate.new File.read "#{Rails.root}/lib/assets/server-cert.pem"
    
    # Load App SubCA cert
    @app = App.find_by_uuid(params[:uuid])
    app_cert = OpenSSL::X509::Certificate.new(@app.ca_cert)
    
    pkcs7 = OpenSSL::PKCS7.new
    pkcs7.type = 'signed'
    pkcs7.certificates = [ca_cert, app_cert]
    
    # render text: , status: 200 and return
    # send_data pkcs7.to_der, type: 'application/x-x509-ca-cert', filename: 'cacerts.der', disposition: 'inline'
  
    render text: Base64.encode64(pkcs7.to_pem), status: 200 and return
  
    # Need to include OldWithOld, OldWithNew and NewWithOld when appropriate
  
  end
  
  # POST
  def simpleenroll
    
    csr_pem = Base64.decode64(request.raw_post)
    
    csr = OpenSSL::X509::Request.new(csr_pem)
    
    raise 'CSR can not be verified' unless csr.verify csr.public_key
    
    uuid = csr.subject.to_a.select { |name| name[0] == 'OU' }.last[1]
    
    @entity = EndEntity.find_by_uuid(uuid)
    
    # Load the CA cert for this app
    @app = App.find_by_uuid(params[:uuid])
    ca_cert = OpenSSL::X509::Certificate.new @app.ca_cert
    # Sign it with the CA key for this app
    ca_key = OpenSSL::PKey::RSA.new @app.ca_key
    
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
    
    puts csr_cert.to_pem
    
    certificate = Certificate.new(certificate: csr_cert.to_der, expires_at: csr_cert.not_after, status: 'V', distinguished_name: csr_cert.subject.to_s, serial_number: csr_cert.serial)
    @entity.certificates << certificate
    @entity.update_attributes( status: 2 )
    
    headers['Content-Type'] = "application/pkcs7-mime"
    headers['Content-Transfer-Encoding'] = "base64"
    headers['smime-type'] = "certs-only"
    
    pkcs7 = OpenSSL::PKCS7.new
    pkcs7.type = 'signed'
    pkcs7.certificates = [csr_cert]
    
    # render text: , status: 200 and return
    # send_data pkcs7.to_der, type: 'application/x-x509-ca-cert', filename: 'cacerts.der', disposition: 'inline'
  
    render text: Base64.encode64(pkcs7.to_pem), status: 200 and return
  
  end
  
  # POST
  def simplereenroll
  
    csr_pem = Base64.decode64(request.raw_post)
    
    csr = OpenSSL::X509::Request.new(csr_pem)
    
    raise 'CSR can not be verified' unless csr.verify csr.public_key
    
    # Get the last created certificate and compare the subject name
    
    uuid = csr.subject.to_a.select { |name| name[0] == 'OU' }.last[1]
    
    @entity = EndEntity.find_by_uuid(uuid)
    
    @certificate = @entity.certificates.order("created_at").last
    
    if @certificate.distinguished_name = csr.subject.to_s

      # Load the CA cert for this app
      @app = App.find_by_uuid(params[:uuid])
      ca_cert = OpenSSL::X509::Certificate.new @app.ca_cert
      # Sign it with the CA key for this app
      ca_key = OpenSSL::PKey::RSA.new @app.ca_key

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

      puts csr_cert.to_pem

      certificate = Certificate.new(certificate: csr_cert.to_der, expires_at: csr_cert.not_after, status: 'V', distinguished_name: csr_cert.subject.to_s, serial_number: csr_cert.serial)
      @entity.certificates << certificate
      @entity.update_attributes( status: 2 )

      headers['Content-Type'] = "application/pkcs7-mime"
      headers['Content-Transfer-Encoding'] = "base64"
      headers['smime-type'] = "certs-only"

      pkcs7 = OpenSSL::PKCS7.new
      pkcs7.type = 'signed'
      pkcs7.certificates = [csr_cert]

      render text: Base64.encode64(pkcs7.to_pem), status: 200 and return

    else
      
      raise 'CSR subject doesn\'t match existing Certificate'
      
    end
    
  end

  # Clients MUST be able to process the Simple PKI Response.  The Simple
  # PKI Response consists of a SignedData with no EncapsulatedContentInfo
  # and no SignerInfo.  The certificates requested in the PKI Response
  # are returned in the certificate field of the SignedData.
  # 
  # Clients MUST NOT assume the certificates are in any order.  Servers
  # SHOULD include all intermediate certificates needed to form complete
  # certification paths to one or more trust anchors, not just the newly
  # issued certificate(s).  The server MAY additionally return CRLs in
  # the CRL bag.  Servers MAY include the self-signed certificates.
  # Clients MUST NOT implicitly trust included self-signed certificate(s)
  # merely due to its presence in the certificate bag.  In the event
  # clients receive a new self-signed certificate from the server,
  # clients SHOULD provide a mechanism to enable the user to use the
  # certificate as a trust anchor.  (The Publish Trust Anchors control
  # (Section 6.15) should be used in the event that the server intends
  # the client to accept one or more certificates as trust anchors.  This
  # requires the use of the Full PKI Response message.)

  # RFC 5272 - Certificate Management Messages over CMS
  # RFC 5652 - Cryptographic Message Syntax (CMS)
  # RFC 2315 - PKCS#7

end
