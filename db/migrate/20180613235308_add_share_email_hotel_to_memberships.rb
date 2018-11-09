class AddShareEmailHotelToMemberships < ActiveRecord::Migration[4.2]
  def change
    add_column :memberships, :share_email_hotel, :boolean
  end
end
