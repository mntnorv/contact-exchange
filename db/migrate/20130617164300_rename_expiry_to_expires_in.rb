class RenameExpiryToExpiresIn < ActiveRecord::Migration
  def change
    rename_column :users, :expiry, :expires_in
  end
end