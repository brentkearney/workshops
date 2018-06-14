class AddShareEmailHotelToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :share_email_hotel, :boolean
  end
end
