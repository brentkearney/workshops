class AddTemplateToEvents < ActiveRecord::Migration
  def change
    add_column :events, :template, :boolean, default: false
  end
end
