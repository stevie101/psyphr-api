class Certificate < ActiveRecord::Base
  
  belongs_to :certificatable, polymorphic: true

  def revoke
    
    update_attributes( status: 'R', revoked_at: Time.now )

  end

end
