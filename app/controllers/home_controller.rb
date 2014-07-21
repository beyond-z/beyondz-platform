class HomeController < ApplicationController
  # The index will show the assignments until we make a dashboard.
  def index
    @assignment_definitions = AssignmentDefinition.all
  end
end
