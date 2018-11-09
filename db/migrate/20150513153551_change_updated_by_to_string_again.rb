class ChangeUpdatedByToStringAgain < ActiveRecord::Migration[4.2]
  def change
    change_column :schedules, :updated_by, :string
    change_column :lectures, :updated_by, :string
  end
end
