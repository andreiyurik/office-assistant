class BookingsController < ApplicationController
  def create
    date = booking_date
    desk = Resource.desks.find(params[:resource_id])
    booking = Current.user.bookings.new(resource: desk, starts_at: date.beginning_of_day)

    Booking.transaction do
      # Choosing another desk on a day you already have one is a move, not an
      # error: the old booking is cancelled and the new one takes its place.
      desk_booking_on(date)&.update!(state: "cancelled")
      raise ActiveRecord::Rollback unless booking.save
    end

    if booking.persisted?
      redirect_to desks_path(date: date)
    else
      redirect_to desks_path(date: date), inertia: {
        errors: { booking: booking.errors.full_messages.first }
      }
    end
  rescue ActiveRecord::RecordNotUnique
    # The unique index caught two people clicking the same desk at once.
    redirect_to desks_path(date: date), inertia: {
      errors: { booking: "Это место успели занять. Выберите другое — свободные подсвечены на карте." }
    }
  end

  def destroy
    booking = Current.user.bookings.find(params[:id])
    booking.update!(state: "cancelled")

    redirect_to desks_path(date: booking.starts_at.to_date)
  end

  private
    def booking_date
      Date.iso8601(params[:date])
    rescue ArgumentError, TypeError
      Date.current
    end

    def desk_booking_on(date)
      Current.user.bookings.active.on_date(date)
        .where(resource_id: Resource.where(kind: "desk").select(:id))
        .first
    end
end
