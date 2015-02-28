class AddSerialNumberToApps < ActiveRecord::Migration
  def change
    add_column :sec_apps, :serial_number, :integer, :limit => 5
  end
end
