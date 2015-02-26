class AddCrlCountToApps < ActiveRecord::Migration
  def change
    add_column :apps, :crl_count, :integer, default: 0
  end
end
