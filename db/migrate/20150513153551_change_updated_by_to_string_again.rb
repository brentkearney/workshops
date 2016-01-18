class ChangeUpdatedByToStringAgain < ActiveRecord::Migration
  def change
    change_column :schedules, :updated_by, :string
    change_column :lectures, :updated_by, :string
  end
end
