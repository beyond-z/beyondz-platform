class SubmitController < ApplicationController
 
  # Action to handle assignment submissions. 
  def new 
    render
  end
 
  # Action to POST the assignment submission to the Leadership Coach.
  def create 
          
    # You can also use OAuth. See document of
    # GoogleDrive.login_with_oauth for details.
    session = GoogleDrive.login(ENV['GOOGLE_DRIVE_EMAIL'], ENV['GOOGLE_DRIVE_PASSWORD'])

    # Initially set to key = 0AhkyYmQz77njdHpMeXRpNFUtZHViaWxQMWpfVkpuZmc which corresponds to the 
    # "Assignment Submissions - Career Prep and Leadership Academy.gdoc"
    doc = session.spreadsheet_by_key(ENV['GOOGLE_SUBMISSION_DOC_KEY'])
    
    ws = doc.worksheet_by_title(ws_name(params[:userEmail]))
   
    # Assuming the worksheet has the following columns, populate it.
    # Student Name  | Student Email  |  Assignment  |   Submission URL 
    firstEmptyRow = ws.num_rows() + 1
    ws[firstEmptyRow, 1] = student_name(:userEmail)
    ws[firstEmptyRow, 2] = params[:userEmail] 
    ws[firstEmptyRow, 3] = assignment_name(params[:assignment_id])
    ws[firstEmptyRow, 4] = params[:submissionUrl]
    ws.save()    

  end

   # Takes an email address and looks up the name of the worksheet for that student
   def ws_name(userEmail)
    #BTODO:
    return "School 1"
  end

   # Looks up the student's name from their email address
   def student_name(userEmail)
     #BTODO:
     return "Joe Smoe"
   end

   # Translates the specified assignmentId to the display name
   def assignment_name(assignmentId)
     #BTODO:
     return assignmentId
   end

end
