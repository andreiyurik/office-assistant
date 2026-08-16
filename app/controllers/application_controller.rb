class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_csrf_cookie

  # Every page needs the person in the header and the check-in reminder, so both
  # are shared instead of being repeated in each controller.
  inertia_share current_user: -> { current_user_props },
                pending_check_in: -> { pending_check_in_props }

  private
    # Inertia reads the token from this cookie and sends it back in a header on
    # every non-GET request, which is what Rails checks.
    def set_csrf_cookie
      cookies["XSRF-TOKEN"] = { value: form_authenticity_token, same_site: :lax }
    end

    def current_user_props
      return nil if Current.user.nil?

      {
        id: Current.user.id,
        name: Current.user.name,
        team_name: Current.user.team.name,
        zone_name: Current.user.team.zone.name
      }
    end

    # The room booking that can be confirmed right now, if there is one. It is
    # shown on every page: the person should not have to go looking for the
    # check-in button before their slot is taken away.
    def pending_check_in_props
      return nil if Current.user.nil?

      booking = Current.user.bookings
        .where(state: "booked", resource_id: Resource.where(kind: "room").select(:id))
        .where(starts_at: ..(Time.current + Booking::CHECK_IN_OPENS_BEFORE))
        .where(ends_at: Time.current..)
        .includes(:resource)
        .order(:starts_at)
        .first
      return nil if booking.nil?

      {
        id: booking.id,
        room_name: booking.resource.name,
        starts_at: booking.starts_at.iso8601,
        releases_at: (booking.starts_at + Booking::RELEASE_AFTER).iso8601
      }
    end
end
