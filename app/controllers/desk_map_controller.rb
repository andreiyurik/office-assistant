class DeskMapController < ApplicationController
  def show
    render inertia: "desk_map/show"
  end
end
