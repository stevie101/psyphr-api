require 'uuidtools'
class App < ActiveRecord::Base
  has_many :end_entities
  belongs_to :user

  before_create :generate_uuid
  
  def generate_uuid
    self.uuid = UUIDTools::UUID.timestamp_create.to_s
  end

end
