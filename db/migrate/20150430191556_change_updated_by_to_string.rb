class ChangeUpdatedByToString < ActiveRecord::Migration
  def change
    change_column :memberships, :updated_by, :string
    change_column :people, :updated_by, :string
    change_column :events, :updated_by, :string
  end
end
