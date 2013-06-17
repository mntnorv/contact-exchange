class RenameHashToToken < ActiveRecord::Migration
  def change
    rename_column :users, :user_hash, :user_token
  end
end