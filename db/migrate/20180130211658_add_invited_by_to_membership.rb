class AddInvitedByToMembership < ActiveRecord::Migration
  def change
    add_column :memberships, :invited_by, :string
    add_column :memberships, :invited_on, :datetime
  end
end
