require 'openssl'
class ApiController < ApplicationController
  def test
  
    data = "some data from stephen"
  
    puts "data: " << data
  
    cipher = OpenSSL::Cipher.new('AES-128-CBC')
    cipher.encrypt
    key = cipher.random_key # also sets the generated key on the Cipher
    iv = cipher.random_iv # also sets the generated IV on the Cipher
    encrypted = cipher.update(data) + cipher.final
    
    puts "encrypted: " << encrypted
    
    decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    decipher.decrypt
    decipher.key = key
    decipher.iv = iv

    plain = decipher.update(encrypted) + decipher.final
    
    puts "plain: " << plain
  
  
    device = Device.find(1)
    cert = OpenSSL::X509::Certificate.new(device.cert)
  
    # Encrypt some data
    pkcs7 = OpenSSL::PKCS7.encrypt([cert], data, cipher, OpenSSL::PKCS7::BINARY)
    puts pkcs7.to_pem
    
    private_key_pem = "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAyTC5JNSnrYqptZRMprYlwT5XxOE/dtG9HdjhhDK7aS/87vKj
j0wdStW+deVulh6427kZEPGVTEIS8HUr6h0JbVjjlY5Ae3epwgz8L0KSAGQ4VLKs
xxs9XWbz8CM4z8l/Qd0G2y9owI6edPr43hY8Mwjfa16FNvKQoWaZDb1l/JJ4v8n5
FkfJPiQO4IREBmNk049B7YqOdRTdM4sXvz3ped/K6yg6FtoBqrbk+KL1ZGWjIBJj
oUMjTPKvgMZn62ubpMi7JT6DEhwYmErBr0HufCQc8rvcTxUT+sIwqHUf3QeS4FRJ
0X3zAkZPYD/guokYhJA+hsx5HeOWZ/aiL0hq4wIDAQABAoIBAQCqKcGOOyaPC0a6
w3GJV2nbZeVKKdFJp9+yTOuAqoAEWYgueZ6I5rGnx9zNTn4YDmf/vzBKOmoyE3h9
VD0OR/zfNV1X8vbq9qzn6Z+qQT3Hgvx59p1X0dw3EYqkwsWcSSqPBGh2HkUVCAtR
mau/+0JzT7/XyhwV+1cEjAhLrLODyMW0/5kFfOsH5Fh+awGPDRgFKRMV/j2wqLcF
2gMgiu0d1Fpltkoekiw3zKZuvs+rGiMVS7FXVAZh5wN2+EsICcBYm34XJEOeOrmu
AZu5ku4Po8Nf0ZjSzokHZmAitgFHCYLmMkS9BBB7aI7SXOAWNWGvEAZRaxxPS/s2
hZkd7wzRAoGBAPVINMwlewM44GwyIkNq8eJL0ruDTDotj0t3S/zHjwQk9D21+SIH
pkxPsQUd/y8R466ZRDViskUknhI40BPDyhcWOAqH0YxRNxL9+mpx91cIIu7DMQgG
r51AUPmScRICn7/KWjCfohWdEpFNwdvP6O2PWQspRY/rVndrO4pBWXX3AoGBANH7
S2aJaW2z+4o1jF89HQihR9NCyWHyH/4qFi50au62gDyNEdUULedtxRFD0HX2Pcug
2YxdCpCh/gDMnTYbEK6Ly30WtqI5fVtaxHVyoZ0orb+Ovga5N++ckE8Dg4OJDYG1
1+iOgp7WHjzrAYp+xOTk5Tnqtxw1+g7zHuioQkd1AoGARqZmtsqw9Quj8OY74kli
pLkMWQCHq1ZGKQmStJvSgPIX+9J3kSq85swpg/zQ7QDtIPR6phnomWvjsAH3RUom
4qF+wOHAJPebsne/cnujL8ljLnzAmbw7R0MoT8qzkOl6lCa39bt1V15n47yO8z6e
rBaXIlTf+YVi4YDcpIUQPJ8CgYAzFOXf2NfL9zffBG3UkWJpwgpeC2ZALI253/Ur
cei9j6ockNjgtBsCrMJ/E7c3qyKXUdb6fXvfeXj4Ks6n5eel/p4PHSJqzn9/ZNJc
G/nS6J1z9z6lFhPUd4rnndw1eHbPsjQG//wotb//Y9ApJ/OwFzroXwASndLqJhzD
zoLpLQKBgQC2/VFZ6dWjdham3Jc47/Rd5dpLpO2y3gjrb+JNE7Zge3wxGO6TRU42
5POrYiH85pKQoLc4ki/Q8UibPwfzgwkyRpbQb4bXqvSrvHWZLcJtAJzihflOPDu/
L4K/koqfBt5gpdQBp86EaZN5hZj6eRzXvFIWcmCWbJtTb8OUmiWDhw==
-----END RSA PRIVATE KEY-----"
    
    private_key = OpenSSL::PKey::RSA.new private_key_pem
    
    # Decrypt file
    profile_encrypted2 = OpenSSL::PKCS7.new(pkcs7.to_pem)
    profile_decrypted = profile_encrypted2.decrypt(private_key, cert)
    puts "decrypted data1: " << profile_decrypted
    
    
    server_key = OpenSSL::PKey::RSA.new File.read("#{Rails.root}/lib/assets/server-key.pem")
    server_cert = OpenSSL::X509::Certificate.new File.read("#{Rails.root}/lib/assets/MedhistoryServer.pem")
    
    # Sign PKCS7
    profile_signed = OpenSSL::PKCS7.sign(server_cert, server_key, pkcs7.to_pem, [], OpenSSL::PKCS7::BINARY)
    
    puts "profile_signed: " << profile_signed.to_pem
    
    # Verify PKCS7
    store = OpenSSL::X509::Store.new
    # store.add_cert(server_cert)
    
    
    verified = profile_signed.verify([server_cert], store, nil, OpenSSL::PKCS7::NOVERIFY)
    
    puts "verified: #{verified}"
  
    render text: 'success'
  end
end
