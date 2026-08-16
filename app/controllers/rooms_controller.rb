class RoomsController < ApplicationController
  DAYS_SHOWN = 5

  def show
    date = selected_date
    slots = Booking.slot_starts_for(date)
    day_bookings = room_bookings(date)

    render inertia: "rooms/show", props: {
      selected_date: date.to_s,
      days: (0...DAYS_SHOWN).map { |offset| (Date.current + offset).to_s },
      slots: slots.map(&:iso8601),
      rooms: rooms_props(slots, day_bookings),
      my_meetings: my_meetings(day_bookings)
    }
  end

  private
    def selected_date
      Date.iso8601(params[:date])
    rescue ArgumentError, TypeError
      Date.current
    end

    def room_bookings(date)
      Booking.on_date(date)
        .where(resource_id: Resource.where(kind: "room").select(:id))
        .includes(:user, :resource)
        .to_a
    end

    def rooms_props(slots, day_bookings)
      taken = day_bookings.select(&:active?).index_by { |booking| slot_key(booking) }
      released = day_bookings.select(&:released?).index_by { |booking| slot_key(booking) }
      now = Time.current

      Resource.rooms.map do |room|
        {
          id: room.id,
          name: room.name,
          capacity: room.capacity,
          cells: cells_for(room, slots, taken, released, now)
        }
      end
    end

    def cells_for(room, slots, taken, released, now)
      previous_group = nil

      slots.map do |slot|
        booking = taken[[ room.id, slot.to_i ]]
        # A meeting longer than one slot is several rows. The follow-up slots
        # are marked so the grid can draw them as one block.
        continuation = booking.present? && booking.group_id == previous_group
        previous_group = booking&.group_id

        {
          state: cell_state(booking),
          person: booking && booking.user_id != Current.user.id ? booking.user.name : nil,
          checked_in: booking&.checked_in? || false,
          continuation: continuation,
          released: booking.nil? && released.key?([ room.id, slot.to_i ]),
          past: slot + Booking::SLOT <= now
        }
      end
    end

    def cell_state(booking)
      return "free" if booking.nil?
      booking.user_id == Current.user.id ? "mine" : "taken"
    end

    def slot_key(booking)
      [ booking.resource_id, booking.starts_at.to_i ]
    end

    # My own bookings of the day, collapsed back into meetings.
    def my_meetings(day_bookings)
      mine = day_bookings.select { |booking| booking.active? && booking.user_id == Current.user.id }

      mine.group_by(&:group_id).map do |_group_id, bookings|
        slots = bookings.sort_by(&:starts_at)
        first = slots.first

        {
          id: first.id,
          room_name: first.resource.name,
          starts_at: first.starts_at.iso8601,
          ends_at: slots.last.ends_at.iso8601,
          checked_in: slots.any?(&:checked_in?),
          can_check_in: first.check_in_open?,
          check_in_opens_at: (first.starts_at - Booking::CHECK_IN_OPENS_BEFORE).iso8601
        }
      end.sort_by { |meeting| meeting[:starts_at] }
    end
end
