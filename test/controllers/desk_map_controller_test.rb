require "test_helper"

class DeskMapControllerTest < ActionDispatch::IntegrationTest
  test "shows the floor map for the chosen day" do
    sign_in_as users(:one)
    Resource.create!(kind: "desk", name: "1", zone: zones(:north), grid_row: 1, grid_col: 1)

    get desks_path(date: Date.current)

    assert_response :success
    assert_match "desk_map/show", response.body
  end
end
