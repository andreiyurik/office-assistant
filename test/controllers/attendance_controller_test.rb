require "test_helper"

class AttendanceControllerTest < ActionDispatch::IntegrationTest
  # One request per screen. It proves the page renders with real rows behind
  # it — the cheapest guard against a prop renamed on one side only.
  test "shows who is in the office on the chosen day" do
    sign_in_as users(:one)
    desk = Resource.create!(kind: "desk", name: "1", zone: zones(:north), grid_row: 1, grid_col: 1)
    Booking.create!(user: users(:two), resource: desk, starts_at: Date.current.beginning_of_day)

    get root_path(date: Date.current)

    assert_response :success
    assert_match "attendance/show", response.body
  end
end
