class AddSentInvitationToMembership < ActiveRecord::Migration
  def change
    add_column :memberships, :sent_invitation, :boolean, default: false
  end
end
