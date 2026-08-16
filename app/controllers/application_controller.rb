class ApplicationController < ActionController::Base
  include Authentication

  # Every screen works on one chosen day and offers the same short strip of
  # days to switch to, so both live here instead of in each controller.
  DAYS_SHOWN = 5

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

    # A day that came from a link or a form. Anything unreadable means today:
    # the screens open on today and a broken date is not worth an error page.
    def selected_date
      Date.iso8601(params[:date])
    rescue ArgumentError, TypeError
      Date.current
    end

    def days_shown
      (0...DAYS_SHOWN).map { |offset| (Date.current + offset).to_s }
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

      booking = Booking.pending_check_in_for(Current.user)
      return nil if booking.nil?

      {
        id: booking.id,
        room_name: booking.resource.name,
        starts_at: booking.starts_at.iso8601,
        releases_at: (booking.starts_at + Booking::RELEASE_AFTER).iso8601
      }
    end
end
