class AssignmentFilesController < ApplicationController
  
	def index

		@files = Assignment.find(params[:assignment_id]).files.first

	end

end