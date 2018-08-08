class UpdateInvitationsForeignKeys < ActiveRecord::Migration
  def change
    # remove the old foreign_key
    remove_foreign_key :invitations, :memberships

    # add the new foreign_key
    add_foreign_key :invitations, :memberships, on_delete: :cascade
  end
end
