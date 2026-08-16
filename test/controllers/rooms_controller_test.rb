require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  test "shows the room grid for the chosen day" do
    sign_in_as users(:one)
    room = Resource.create!(kind: "room", name: "Тестовая", zone: zones(:north), capacity: 4)
    Booking.create!(user: users(:one), resource: room, starts_at: Date.current.beginning_of_day.change(hour: 10))

    get rooms_path(date: Date.current)

    assert_response :success
    assert_match "rooms/show", response.body
  end
end
