class AddSerialNumberToApps < ActiveRecord::Migration
  def change
    add_column :apps, :serial_number, :integer, :limit => 5
  end
end
