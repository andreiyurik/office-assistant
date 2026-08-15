class CreateRecurringSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_schedules do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :resource, null: false, foreign_key: true
      t.json :weekdays, null: false, default: []
      t.date :valid_from, null: false
      t.date :valid_to

      t.timestamps
    end
  end
end
