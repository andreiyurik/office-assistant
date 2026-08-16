class DeskMapController < ApplicationController
  DAYS_SHOWN = 5

  def show
    date = selected_date
    bookings = desk_bookings(date)
    my_booking = bookings.values.find { |booking| booking.user_id == Current.user.id }

    render inertia: "desk_map/show", props: {
      selected_date: date.to_s,
      days: (0...DAYS_SHOWN).map { |offset| (Date.current + offset).to_s },
      zones: zones_props(bookings),
      my_booking: my_booking && {
        id: my_booking.id,
        desk_id: my_booking.resource_id,
        desk_name: my_booking.resource.name,
        zone_name: my_booking.resource.zone.name
      },
      default_desk: default_desk_props(bookings),
      recurring: recurring_props
    }
  end

  private
    def selected_date
      Date.iso8601(params[:date])
    rescue ArgumentError, TypeError
      Date.current
    end

    # Active desk bookings of the day, keyed by desk.
    def desk_bookings(date)
      Booking.active.on_date(date)
        .where(resource_id: Resource.where(kind: "desk").select(:id))
        .includes(user: :team, resource: :zone)
        .index_by(&:resource_id)
    end

    # The floor is drawn zone by zone, and each zone keeps the grid positions
    # that come from the seeds.
    def zones_props(bookings)
      Resource.desks.includes(:zone).group_by(&:zone).map do |zone, desks|
        {
          id: zone.id,
          name: zone.name,
          is_mine: zone.id == Current.user.team.zone_id,
          free_count: desks.count { |desk| bookings[desk.id].nil? },
          min_row: desks.map(&:grid_row).min,
          min_col: desks.map(&:grid_col).min,
          desks: desks.map { |desk| desk_props(desk, bookings[desk.id]) }
        }
      end.sort_by { |zone| [ zone[:min_row], zone[:min_col] ] }
    end

    def desk_props(desk, booking)
      {
        id: desk.id,
        name: desk.name,
        row: desk.grid_row,
        col: desk.grid_col,
        is_default: desk.id == Current.user.default_desk_id,
        taken_by: booking && {
          name: booking.user.name,
          team_name: booking.user.team.name,
          is_me: booking.user_id == Current.user.id,
          is_teammate: booking.user.team_id == Current.user.team_id
        }
      }
    end

    def recurring_props
      schedule = Current.user.recurring_schedule
      return nil if schedule.nil?

      {
        weekdays: schedule.weekdays,
        desk_id: schedule.resource_id,
        desk_name: schedule.resource.name
      }
    end

    def default_desk_props(bookings)
      desk = Current.user.default_desk
      return nil if desk.nil?

      {
        id: desk.id,
        name: desk.name,
        zone_name: desk.zone.name,
        free: bookings[desk.id].nil?
      }
    end
end
