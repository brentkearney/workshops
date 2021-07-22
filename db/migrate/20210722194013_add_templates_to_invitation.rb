class AddTemplatesToInvitation < ActiveRecord::Migration[5.2]
  def change
    add_column :invitations, :templates, :jsonb
  end
end
