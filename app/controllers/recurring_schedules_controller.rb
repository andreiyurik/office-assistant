class RecurringSchedulesController < ApplicationController
  def update
    weekdays = Array(params[:weekdays]).map(&:to_i).uniq.sort
    schedule = Current.user.recurring_schedule

    if weekdays.empty?
      turn_off(schedule)
    else
      turn_on(schedule, weekdays)
    end

    redirect_to desks_path(date: params[:date])
  end

  private
    def turn_off(schedule)
      return if schedule.nil?

      schedule.cancel_future_bookings!
      schedule.destroy!
    end

    def turn_on(schedule, weekdays)
      desk = Resource.desks.find(params[:resource_id])
      schedule ||= Current.user.build_recurring_schedule

      schedule.assign_attributes(resource: desk, weekdays: weekdays, valid_from: Date.current)
      schedule.save!
      schedule.apply!
    end
end
