class Api::EstController < ApplicationController
  
  # GET
  def cacerts
    
    headers['Content-Type'] = "application/pkcs7-mime"
    headers['Content-Transfer-Encoding'] = "base64"
    
    render text: "cert", status: 200 and return
  
  end
  
  # POST
  def simpleenroll
    
    headers['Content-Type'] = "application/pkcs7-mime"
    headers['Content-Transfer-Encoding'] = "base64"
    
    render text: "cert", status: 200 and return
  
  end
  
  # POST
  def simplereenroll
  
    headers['Content-Type'] = "application/pkcs7-mime"
    headers['Content-Transfer-Encoding'] = "base64"
  
    render text: "cert", status: 200 and return
    
  end

end
