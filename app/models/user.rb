class User < ActiveRecord::Base
  has_many :sec_apps
  has_many :end_entities, through: :sec_apps
  
  has_secure_password
  
end
