class AddRsvpColumnsToMembership < ActiveRecord::Migration[4.2]
  def change
    add_column :memberships, :own_accommodation, :boolean, default: false
    add_column :memberships, :has_guest, :boolean, default: false
    add_column :memberships, :guest_disclaimer, :boolean, default: false
    add_column :memberships, :special_info, :string
    add_column :memberships, :stay_id, :string
  end
end
