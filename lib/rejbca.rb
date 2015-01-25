require 'rjb'
require 'singleton'
class Rejbca
  include Singleton
  
  @@base_dir = "~/Library/Java/Extensions"
  @@EjbcaWSHandler = nil
  
  def initialize
    
    
    
    # # Load Java Jars
    # jars = ["ejbca-ws-client.jar", "ejbca-ws-ejb.jar", "ejbca-ws.jar", "cesecore-common.jar", "cesecore-ejb-interface.jar", "cesecore-ejb.jar", "cesecore-entity.jar", "commons-codec-1.10.jar"]
    # 
    # classes = ["java.security.Security", "java.security.Provider", "java.net.*", "javax.xml.namespace.QName", "org.ejbca.core.protocol.ws.client.gen.*", "org.cesecore.certificates.endentity.*"]
    # 
    # jars.each do |jar|
    #   Rjb::load(jar)
    # end
    # 
    # # Import classes
    # @@HostnameVerifier = Rjb::import("javax.net.ssl.HostnameVerifier")
    # @@SSLSession = Rjb::import("javax.net.ssl.SSLSession")
    # @@HttpsURLConnection = Rjb::import("javax.net.ssl.HttpsURLConnection")
    # 
  	# val hv = new HostnameVerifier() {
  	# 	def verify(urlHostName:String, session:SSLSession):Boolean = {
  	# 		System.out.println("Warning: URL Host: " + urlHostName + " vs. " + session.getPeerHost())
  	# 		return true;
  	# 	}
  	# }
    # 
    # 
    # 
  	# @@HttpsURLConnection.setDefaultHostnameVerifier(hv);
    
    puts "===="
    puts @@base_dir + "/sec-assembly-0.1.jar"
    puts "===="

    Rjb::load(@@base_dir + "/sec-assembly-0.1.jar")
    
    hashmap = Rjb::import("java.util.HashMap").new

    hashmap.put("username", "ste101")
    hashmap.put("password", "schiffer")
    hashmap.put("subjectDN", "CN=customer1cn,OU=user1,OU=customer1,L=London,C=UK")
    
    @@EjbcaWSHandler = Rjb::import("EjbcaWSHandler")
    # 
    @ejbcaHandler = @@EjbcaWSHandler.new
    
    
    # 
    @ejbcaHandler.setTrustStorePath("#{Rails.root}/lib/truststore")
    @ejbcaHandler.setKeyStorePath("#{Rails.root}/lib/newca.jks")
    @ejbcaHandler.setTrustStorePassword("changeit")
    @ejbcaHandler.setKeyStorePassword("schiffer")
    
    @ejbcaHandler.connectToWS
    
    # 
    # result = @ejbcaHandler.generateCertificate
    # 
    # puts "+_+_+_+_+"
    # puts "+#{result}+"
    # puts "+_+_+_+_+"

  end
  
  def test
    
    if @@EjbcaWSHandler
      result = @ejbcaHandler.generateCertificate

      puts "+_+_+_+_+"
      puts "+#{result}+"
      puts "+_+_+_+_+"
    end
    
    "hello world"
    
  end
  
  def add_user(user = {})
    
    if user.length > 0
      
      hashmap = Rjb::import("java.util.HashMap").new
      
      user.each_pair{ |k, v| hashmap.put(k, v) }
      
      @ejbcaHandler.addUser(hashmap)
      
    end
    
  end
  
  def update_user(user = {})
    
  end
  
  def delete_user(username)
    
  end
  
  def enrol(user = {}, csr = nil)
    
    if user.length > 0 and csr
      
      hashmap = Rjb::import("java.util.HashMap").new
      
      user.each_pair{ |k, v| hashmap.put(k, v) }
      
      certificate = @ejbcaHandler.generateCertificate(hashmap, csr)
        
      if certificate
        return certificate
      else
        return nil
      end
      
    end
    
  end
  
end