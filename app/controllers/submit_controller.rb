class SubmitController < ApplicationController
 
  # Action to handle assignment submissions. 
  def new 
    render
  end
 
  # Action to POST the assignment submission to the Leadership Coach.
  def create 
    
    # An array of userInfo objects are stored in the USER_INFOS env var as a JSON string in this format:
    # '{ "brian.sadler@beyondz.org" : {"name" : "Brian Sadler", "school" : "School 1" }, ... }'

    # This gets the info for the user using their email address as the key
    # IMPORTANT: if this isn't working, check that the ".env" file has the correct info and 
    # is pushed to your environment
    userInfo = JSON.parse(ENV['USER_INFOS'])[params[:userEmail]]

    #BTODO: validate that an object for this email address was found

    # Info on assignment is stored in teh ASSIGNMENT_INFO env var as a JSON string in the following format:
    # { "assignmentId" : "Assignment Display Name", ... }
    assignmentIdToName = JSON.parse(ENV['ASSIGNMENT_INFO'])

    # You can also use OAuth. See document of
    # GoogleDrive.login_with_oauth for details.
    session = GoogleDrive.login(ENV['GOOGLE_DRIVE_EMAIL'], ENV['GOOGLE_DRIVE_PASSWORD'])

    # Initially set to key = 0AhkyYmQz77njdHpMeXRpNFUtZHViaWxQMWpfVkpuZmc which corresponds to the 
    # "Assignment Submissions - Career Prep and Leadership Academy.gdoc"
    doc = session.spreadsheet_by_key(ENV['GOOGLE_SUBMISSION_DOC_KEY'])
    
    ws = doc.worksheet_by_title(userInfo["school"])
   
    # Assuming the worksheet has the following columns, populate it.
    # Student Name  | Student Email  |  Assignment  |   Submission URL 
    firstEmptyRow = ws.num_rows() + 1
    ws[firstEmptyRow, 1] = userInfo["name"] 
    ws[firstEmptyRow, 2] = params[:userEmail] 
    ws[firstEmptyRow, 3] = assignmentIdToName[params[:assignment_id]]
    ws[firstEmptyRow, 4] = params[:submissionUrl]
    ws.save()    

  end

end
