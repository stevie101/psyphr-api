class Certificate < ActiveRecord::Base
  
  belongs_to :certificatable, polymorphic: true

end
