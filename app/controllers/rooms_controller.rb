class RoomsController < ApplicationController
  def show
    date = selected_date
    day_bookings = room_bookings(date)

    render inertia: "rooms/show", props: {
      selected_date: date.to_s,
      days: days_shown,
      hours: { open: Booking::OPEN_HOUR, close: Booking::CLOSE_HOUR },
      slot_minutes: Booking::SLOT_MINUTES,
      max_slots: Booking::MAX_MEETING_SLOTS,
      rooms: Resource.rooms.map { |room| { id: room.id, name: room.name, capacity: room.capacity } },
      meetings: meetings(day_bookings),
      released_slots: released_slots(day_bookings)
    }
  end

  private
    def room_bookings(date)
      Booking.rooms.on_date(date).includes(:user, :resource).to_a
    end

    # Active bookings of the day collapsed back into meetings: a meeting longer
    # than one slot is several rows with one group_id, the calendar draws it as
    # one block. Everyone's meetings are here; `mine` tells them apart.
    def meetings(day_bookings)
      active = day_bookings.select(&:active?)

      active.group_by(&:group_id).map do |_group_id, bookings|
        slots = bookings.sort_by(&:starts_at)
        first = slots.first
        mine = first.user_id == Current.user.id

        {
          id: first.id,
          room_id: first.resource_id,
          room_name: first.resource.name,
          starts_at: first.starts_at.iso8601,
          ends_at: slots.last.ends_at.iso8601,
          mine: mine,
          person: mine ? nil : first.user.name,
          checked_in: slots.any?(&:checked_in?),
          # One check-in covers the meeting, so the button stays available
          # while any of its slots is still open.
          can_check_in: mine && slots.any?(&:check_in_open?),
          check_in_opens_at: (first.starts_at - Booking::CHECK_IN_OPENS_BEFORE).iso8601
        }
      end.sort_by { |meeting| meeting[:starts_at] }
    end

    # Slots that were booked and released automatically and are still empty.
    # Shown as a hint, so people learn that a free room in the calendar may be
    # one nobody came to.
    def released_slots(day_bookings)
      taken = day_bookings.select(&:active?).map { |booking| slot_key(booking) }

      day_bookings.select(&:released?)
        .reject { |booking| taken.include?(slot_key(booking)) }
        .uniq { |booking| slot_key(booking) }
        .map do |booking|
          {
            room_id: booking.resource_id,
            starts_at: booking.starts_at.iso8601,
            ends_at: booking.ends_at.iso8601
          }
        end
    end

    def slot_key(booking)
      [ booking.resource_id, booking.starts_at.to_i ]
    end
end
