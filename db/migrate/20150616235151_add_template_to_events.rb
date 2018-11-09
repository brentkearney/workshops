class AddTemplateToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :template, :boolean, default: false
  end
end
