class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :resource, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :group_id, null: false
      t.string :state, null: false, default: "booked"
      t.datetime :checked_in_at

      t.timestamps
    end

    add_index :bookings, :group_id
    add_index :bookings, :starts_at

    # The whole double-booking guarantee lives here, not in the controller.
    # Partial: a released or cancelled booking stays in the table for history
    # and for the UI marker, but must not keep the slot busy.
    add_index :bookings, [ :resource_id, :starts_at ],
      unique: true,
      where: "state IN ('booked', 'checked_in')",
      name: "index_bookings_on_active_resource_slot"

    # One person cannot be in two places at the same moment. For desks the
    # slot starts at midnight, so this also means one desk per person per day.
    add_index :bookings, [ :user_id, :starts_at ],
      unique: true,
      where: "state IN ('booked', 'checked_in')",
      name: "index_bookings_on_active_user_slot"
  end
end
