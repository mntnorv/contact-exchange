class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :id
      t.text :email
      t.string :name
      t.string :user_hash
      t.string :access_token
      t.string :refresh_token
      t.integer :last_refresh

      t.timestamps
    end

    add_index :users, :user_hash, :unique => true
  end
end
