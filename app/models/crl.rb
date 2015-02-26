class Crl < ActiveRecord::Base
  belongs_to :crlable, polymorphic: true
end
