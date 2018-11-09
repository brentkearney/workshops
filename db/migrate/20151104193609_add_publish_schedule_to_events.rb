class AddPublishScheduleToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :publish_schedule, :boolean, default: false
  end
end
