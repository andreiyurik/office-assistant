class AttendanceController < ApplicationController
  def show
    date = selected_date
    people = people_in_office(date)
    my_booking = my_desk_booking(date)

    render inertia: "attendance/show", props: {
      selected_date: date.to_s,
      my_desk: my_booking && {
        name: my_booking.resource.name,
        zone_name: my_booking.resource.zone.name
      },
      days: days_shown,
      teams: Team.order(:name).map { |team| { id: team.id, name: team.name } },
      selected_team_id: selected_team&.id,
      people: people,
      teammates_count: people.count { |person| person[:is_teammate] }
    }
  end

  private
    def selected_team
      @selected_team ||= Team.find_by(id: params[:team_id])
    end

    def my_desk_booking(date)
      Booking.active.on_date(date)
        .where(user: Current.user, resource_id: Resource.where(kind: "desk").select(:id))
        .includes(resource: :zone)
        .first
    end

    # A person is in the office when they hold a desk for that day.
    def people_in_office(date)
      bookings = Booking.active.on_date(date)
        .joins(:user, :resource)
        .includes(user: :team, resource: :zone)
        .where(resources: { kind: "desk" })
      bookings = bookings.where(users: { team_id: selected_team.id }) if selected_team

      people = bookings.map do |booking|
        {
          id: booking.user_id,
          name: booking.user.name,
          team_name: booking.user.team.name,
          is_teammate: booking.user.team_id == Current.user.team_id,
          is_me: booking.user_id == Current.user.id,
          desk_name: booking.resource.name,
          zone_name: booking.resource.zone.name
        }
      end

      people.sort_by do |person|
        [ person[:is_me] ? 0 : 1, person[:is_teammate] ? 0 : 1, person[:name] ]
      end
    end
end
