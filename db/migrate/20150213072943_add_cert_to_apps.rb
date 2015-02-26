class AddCertToApps < ActiveRecord::Migration
  def change
    add_column :apps, :client_cert, :binary, after: :name
    add_column :apps, :client_key, :binary, after: :client_cert
  end
end
