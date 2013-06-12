class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :id
      t.string :user_hash
      t.string :access_token
      t.string :refresh_token
      t.integer :last_refresh
      t.text :email

      t.timestamps
    end
  end
end
