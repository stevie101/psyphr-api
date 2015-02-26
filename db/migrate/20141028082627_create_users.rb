class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|

      t.string :slug
      t.string :firstname
      t.string :surname
      t.string :email
      t.string :locality
      t.string :country
      t.string :password_digest
      t.timestamps
    end
  end
end
