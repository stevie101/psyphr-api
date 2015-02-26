class User < ActiveRecord::Base
  has_many :apps
  has_many :end_entities, through: :apps
  
  has_secure_password
  
end
