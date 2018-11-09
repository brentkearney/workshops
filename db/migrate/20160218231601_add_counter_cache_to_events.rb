class AddCounterCacheToEvents < ActiveRecord::Migration[4.2]
  def change
    change_table :events do |t|
      t.integer :confirmed_count, default: 0, null: false
    end

    reversible do |dir|
      dir.up { data }
    end
  end

  def data
    execute <<-SQL.squish
        UPDATE events
           SET confirmed_count = (SELECT count(1)
                                    FROM memberships
                                   WHERE memberships.event_id = events.id
                                     AND memberships.attendance = 'Confirmed')
    SQL
  end
end
