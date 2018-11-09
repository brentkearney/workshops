class AddFieldsToMembership < ActiveRecord::Migration[4.2]
  def change
    add_column :memberships, :billing, :string
    add_column :memberships, :reviewed, :boolean, default: false
    add_column :memberships, :room, :string
  end
end
