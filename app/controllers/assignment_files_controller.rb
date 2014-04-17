class AssignmentFilesController < ApplicationController
  
	def index
		@assignment = TestAssignment.find(params[:assignment_id])
		@files = @assignment.files.where({file_type: 'document'})[0..0]
	end

	def update
  	@file = AssignmentFile.find(params[:id]).update_attributes(assignment_file_params)
	
  	redirect_to assignment_files_path
	end

	private

	def assignment_file_params
	  params.require(:assignment_file).permit(:document, :image, :video, :audio)
	end

end