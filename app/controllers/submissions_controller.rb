class SubmissionsController < ApplicationController
  #before_action :set_submission, only: [:show, :edit, :update, :destroy]

  # GET /submissions
  # GET /submissions.json
  def index

    @submissions = Submission.for_assignment(params[:assignment_id])

    @submission = Submission.new
  end

  # def index
  #   @assignment = TestAssignment.find(params[:assignment_id])
  #   @files = @assignment.files.where({file_type: 'document'})[0..0]
  # end

  def update
    #file = Submission.find(params[:id]).update_attributes(submission_params)

    Rails.logger.info submission_params
  
    redirect_to assignment_submissions_path(params[:assignment_id])
  end

  # GET /submissions/1
  # GET /submissions/1.json
  # def show
  # end

  # GET /submissions/new
  # def new
  #   @user_submission = UserSubmission.new
  # end

  # GET /submissions/1/edit
  # def edit
  # end

  # POST /submissions
  # POST /submissions.json
  # def create
  #   @submission = Submission.new(submission_params)

  #   if @submission.valid?

  #      # Get the info for this specific user using the email as the hash key
  #      userInfo = $userInfos[@submission.email]
       
  #      # Info on assignment is stored in the following format:
  #      # { "assignmentId" : "Assignment Display Name", ... }
  #      assignmentIdToName = JSON.parse(File.read(::Rails.root.join("config", "assignmentInfo.json")))


  #      ######### 
  #      # We're using the google_drive gem.  The API is here: http://gimite.net/doc/google-drive-ruby/
  #      ########
    
  #      # You can also use OAuth. See document of GoogleDrive.login_with_oauth for details.
  #      session = GoogleDrive.login(ENV['GOOGLE_DRIVE_EMAIL'], ENV['GOOGLE_DRIVE_PASSWORD'])
  #      doc = session.spreadsheet_by_key(userInfo["documentKey"])
  #      ws = doc.worksheets[0]
   
  #      # Assuming the worksheet has the following columns, populate it.
  #      # Student Name  | Student Email  |  Coach  |  Assignment  |   Submission URL  |  Date Submitted  |  Feedback 
  #      firstEmptyRow = ws.num_rows() + 1
  #      ws[firstEmptyRow, 1] = userInfo["name"] 
  #      ws[firstEmptyRow, 2] = @submission.email
  #      ws[firstEmptyRow, 3] = userInfo["coach"]  
  #      ws[firstEmptyRow, 4] = assignmentIdToName[params[:assignment_id]]
  #      ws[firstEmptyRow, 5] = @submission.url
  #      ws[firstEmptyRow, 6] = Time.now
  #      ws.save()    
       
  #     render action: 'create'
  #   else
  #     render action: 'new'
  #   end

  # end

  # PATCH/PUT /submissions/1
  # PATCH/PUT /submissions/1.json
  # def update
  #   respond_to do |format|
  #     if @submission.update(submission_params)
  #       format.html { redirect_to @submission, notice: 'Submission was successfully updated.' }
  #       format.json { head :no_content }
  #     else
  #       format.html { render action: 'edit' }
  #       format.json { render json: @submission.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /submissions/1
  # DELETE /submissions/1.json
  # def destroy
  #   @submission.destroy
  #   respond_to do |format|
  #     format.html { redirect_to submissions_url }
  #     format.json { head :no_content }
  #   end
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    # def set_submission
    #   @submission = Submission.find(params[:id])
    # end

    # Never trust parameters from the scary internet, only allow the white list through.
    def submission_params
      params.require(:submission).permit(:files)
    end
end
