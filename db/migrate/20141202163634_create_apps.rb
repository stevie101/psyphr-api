class CreateApps < ActiveRecord::Migration
  def change
    create_table :apps do |t|
      t.string :uuid
      t.references :user                 # ID of the user that this device belongs to
      t.string :name
      t.timestamps
    end
  end
end
