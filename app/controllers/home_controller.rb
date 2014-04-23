class HomeController < ApplicationController
  def index
  	@assignment_definitions = AssignmentDefinition.all	
  end
end
