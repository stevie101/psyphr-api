class CreateSecApps < ActiveRecord::Migration
  def change
    create_table :sec_apps do |t|
      t.string :uuid
      t.references :user # ID of the user that this device belongs to
      t.string :name
      t.binary :client_key
      t.binary :ca_key
      t.timestamps
      t.timestamps
    end
  end
end
