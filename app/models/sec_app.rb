require 'uuidtools'
class SecApp < ActiveRecord::Base

  has_many :certificates, as: :certificatable
  has_many :crls, as: :crlable
  has_many :end_entities
  belongs_to :user

  before_create :generate_uuid
  
  def generate_uuid
    self.uuid = UUIDTools::UUID.timestamp_create.to_s
  end

  def client_certificate
    certificates.where("distinguished_name LIKE ?", "%OU=client%").first
  end
  
  def ca_certificate
    certificates.where("distinguished_name LIKE ?", "%OU=ca%").first
  end
  
  def has_client_certificate
    client_certificate != nil
  end
  
  def has_ca_certificate
    ca_certificate != nil
  end
  
end
