class RoomsController < ApplicationController
  def show
    render inertia: "rooms/show"
  end
end
