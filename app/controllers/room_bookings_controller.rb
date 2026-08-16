class RoomBookingsController < ApplicationController
  def create
    room = Resource.rooms.find(params[:resource_id])
    starts_at = slot_start
    slots = params[:slots].to_i.clamp(1, Booking::MAX_MEETING_SLOTS)

    Booking.book_meeting!(user: Current.user, room: room, starts_at: starts_at, slots: slots)

    redirect_to rooms_path(date: starts_at.to_date)
  rescue ActiveRecord::RecordInvalid => error
    redirect_to rooms_path(date: starts_at.to_date), inertia: {
      errors: { booking: error.record.errors.full_messages.first }
    }
  rescue ActiveRecord::RecordNotUnique
    # The unique index caught two people taking the same slot at once.
    redirect_to rooms_path(date: starts_at.to_date), inertia: {
      errors: { booking: "Этот слот успели занять. Выберите другое время или другую переговорную." }
    }
  end

  def check_in
    booking = Current.user.bookings.rooms.find(params[:id])

    if booking.check_in!
      redirect_to rooms_path(date: booking.starts_at.to_date)
    else
      redirect_to rooms_path(date: booking.starts_at.to_date), inertia: {
        errors: { booking: "Отметиться можно за 10 минут до начала встречи и до её окончания." }
      }
    end
  end

  def destroy
    booking = Current.user.bookings.rooms.find(params[:id])
    booking.cancel_meeting!

    redirect_to rooms_path(date: booking.starts_at.to_date)
  end

  private
    def slot_start
      Time.zone.parse(params[:starts_at].to_s) || Time.current
    end
end
