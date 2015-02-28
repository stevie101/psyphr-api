class AddCrlCountToApps < ActiveRecord::Migration
  def change
    add_column :sec_apps, :crl_count, :integer, default: 0
  end
end
