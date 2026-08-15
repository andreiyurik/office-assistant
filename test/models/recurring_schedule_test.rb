require "test_helper"

class RecurringScheduleTest < ActiveSupport::TestCase
  test "expands into desk bookings on the chosen weekdays only" do
    desk = Resource.create!(kind: "desk", name: "99", zone: zones(:north), grid_row: 9, grid_col: 9)
    monday = Date.current.next_occurring(:monday)

    schedule = RecurringSchedule.create!(
      user: users(:one),
      resource: desk,
      weekdays: [ 1, 3 ],
      valid_from: monday
    )

    bookings = schedule.expand!(from: monday, horizon: 6.days)

    assert_equal [ monday, monday + 2.days ], bookings.map { |booking| booking.starts_at.to_date }
    assert bookings.all? { |booking| booking.resource == desk }
  end
end
