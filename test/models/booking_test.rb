require "test_helper"

class BookingTest < ActiveSupport::TestCase
  setup do
    @room = Resource.create!(kind: "room", name: "Тестовая", zone: zones(:north), capacity: 4)
    @slot = Date.current.beginning_of_day.change(hour: 10)
  end

  test "the same room slot cannot be booked twice" do
    Booking.create!(user: users(:one), resource: @room, starts_at: @slot)

    duplicate = Booking.new(user: users(:two), resource: @room, starts_at: @slot)
    assert_not duplicate.valid?

    # The validation is only there to produce a readable message. The database
    # is what actually prevents two people from taking the same slot.
    duplicate.ends_at = @slot + Booking::SLOT
    duplicate.group_id = SecureRandom.uuid

    assert_raises ActiveRecord::RecordNotUnique do
      duplicate.save(validate: false)
    end
  end

  test "auto-release frees a room booking nobody checked in to" do
    booking = Booking.create!(user: users(:one), resource: @room, starts_at: @slot)

    Booking.release_abandoned!(now: @slot + Booking::RELEASE_AFTER + 1.minute)

    assert_equal "released", booking.reload.state
  end

  test "auto-release frees the whole meeting, not only the slot that has passed" do
    meeting = Booking.book_meeting!(user: users(:one), room: @room, starts_at: @slot, slots: 3)

    Booking.release_abandoned!(now: @slot + Booking::RELEASE_AFTER + 1.minute)

    # The room is empty for the rest of the meeting too, so the rest of it must
    # not stay booked until each slot ages out on its own.
    assert_equal %w[released released released], meeting.map { |booking| booking.reload.state }
  end

  test "auto-release leaves a meeting alone once anybody checked in" do
    group_id = SecureRandom.uuid
    first_half = Booking.create!(
      user: users(:one), resource: @room, starts_at: @slot, group_id: group_id,
      state: "checked_in", checked_in_at: @slot
    )
    second_half = Booking.create!(
      user: users(:one), resource: @room, starts_at: @slot + Booking::SLOT, group_id: group_id
    )

    Booking.release_abandoned!(now: @slot + 1.hour)

    assert_equal "checked_in", first_half.reload.state
    assert_equal "booked", second_half.reload.state
  end
end
