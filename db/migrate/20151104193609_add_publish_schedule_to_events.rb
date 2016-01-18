class AddPublishScheduleToEvents < ActiveRecord::Migration
  def change
    add_column :events, :publish_schedule, :boolean, default: false
  end
end
