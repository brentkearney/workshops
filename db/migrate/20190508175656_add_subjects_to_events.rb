class AddSubjectsToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :subjects, :string
  end
end
