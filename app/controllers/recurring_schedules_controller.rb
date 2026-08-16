class RecurringSchedulesController < ApplicationController
  def update
    weekdays = Array(params[:weekdays]).map(&:to_i).uniq.sort
    schedule = weekdays.empty? ? turn_off : turn_on(weekdays)

    if schedule.nil? || schedule.errors.empty?
      redirect_to desks_path(date: params[:date])
    else
      redirect_to desks_path(date: params[:date]), inertia: {
        errors: { booking: schedule.errors.full_messages.first }
      }
    end
  end

  private
    # Clearing every weekday turns the schedule off: the days ahead stop
    # holding a desk and the schedule itself goes away.
    def turn_off
      schedule = Current.user.recurring_schedule
      return nil if schedule.nil?

      schedule.cancel_future_bookings!
      schedule.destroy!
      nil
    end

    def turn_on(weekdays)
      desk = Resource.desks.find(params[:resource_id])
      schedule = Current.user.recurring_schedule || Current.user.build_recurring_schedule

      schedule.assign_attributes(resource: desk, weekdays: weekdays, valid_from: Date.current)
      schedule.apply! if schedule.save
      schedule
    end
end
