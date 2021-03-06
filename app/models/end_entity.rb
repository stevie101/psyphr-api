require 'uuidtools'

class EndEntity < ActiveRecord::Base

  attr_accessor :password

  belongs_to :sec_app
  has_many :certificates, as: :certificatable
  
  before_create :generate_uuid, :generate_password
  
  def generate_uuid
    self.uuid = UUIDTools::UUID.timestamp_create.to_s
  end

  # Generates a random string of a given length
  # With a mixture of lowercase and uppercase letters and numbers
  def random_string(length)
    o = [('a'..'z'),('A'..'Z'),('0'..'9')].map{|i| i.to_a}.flatten
    (0...length).map{ o[rand(o.length)] }.join
  end

  # Generates an 8 character random number
  # And assigns it to the band's registration code attribute
  def generate_password
    self.password = random_string(32)
    self.e_password = Digest::SHA256.hexdigest(self.password)
  end

end
