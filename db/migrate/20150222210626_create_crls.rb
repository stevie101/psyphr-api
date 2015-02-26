class CreateCrls < ActiveRecord::Migration
  def change
    create_table :crls do |t|
      t.references  :crlable, polymorphic: true, index: true
      t.integer     :number
      t.binary      :crl
      t.datetime    :last_update_at
      t.datetime    :next_update_at
      t.string      :issuer_name
      t.integer     :serial
      t.timestamps
    end
  end
end
