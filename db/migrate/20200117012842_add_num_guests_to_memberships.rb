class AddNumGuestsToMemberships < ActiveRecord::Migration[5.2]
  def change
    add_column :memberships, :num_guests, :integer, null: false, default: 0
  end
end
