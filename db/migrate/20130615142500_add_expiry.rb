class AddExpiry < ActiveRecord::Migration
  def change
    add_column :users, :expiry, :integer, :default => 0
  end
end