class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates do |t|
      t.references :end_entity
      
      t.string :common_name             # CN attribute
      t.string :organisational_unit     # OU attribute
      t.string :organisation            # O attribute
      t.string :locality                # L attribute
      t.string :state                   # S attribute
      t.string :country                 # C attribute
      
      t.datetime :valid_from
      t.datetime :valid_to
      t.string :serial_number
      t.integer :state
      
      t.timestamps
    end
  end
end
