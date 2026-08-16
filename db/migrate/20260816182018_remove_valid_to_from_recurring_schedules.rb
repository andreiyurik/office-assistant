class RemoveValidToFromRecurringSchedules < ActiveRecord::Migration[8.1]
  # Nothing ever wrote this column: turning a schedule off deletes the row.
  def change
    remove_column :recurring_schedules, :valid_to, :date
  end
end
