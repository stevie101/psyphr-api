class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates do |t|
      t.references :certificatable, polymorphic: true, index: true
      t.binary :certificate, limit: 64.kilobytes + 1
      t.string :distinguished_name
      t.datetime :expires_at, default: nil
      t.datetime :revoked_at, default: nil
      t.string :serial_number
      t.string :filename, default: 'unknown'
      t.string :status, default: nil
      t.timestamps
    end

  end
end
