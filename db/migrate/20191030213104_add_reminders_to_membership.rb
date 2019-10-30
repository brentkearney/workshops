class AddRemindersToMembership < ActiveRecord::Migration[5.2]
  def change
    add_column :memberships, :invite_reminders, :string
  end
end
