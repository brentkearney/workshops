class AddInvitedByToMembership < ActiveRecord::Migration[4.2]
  def change
    add_column :memberships, :invited_by, :string
    add_column :memberships, :invited_on, :datetime
  end
end
