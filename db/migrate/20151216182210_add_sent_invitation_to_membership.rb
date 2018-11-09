class AddSentInvitationToMembership < ActiveRecord::Migration[4.2]
  def change
    add_column :memberships, :sent_invitation, :boolean, default: false
  end
end
