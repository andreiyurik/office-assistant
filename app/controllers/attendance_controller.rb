class AttendanceController < ApplicationController
  def show
    render inertia: "attendance/show"
  end
end
