class AddSubcaToApps < ActiveRecord::Migration
  def change
    add_column :apps, :ca_cert, :binary, after: :client_key
    add_column :apps, :ca_key, :binary, after: :ca_cert
  end
end
