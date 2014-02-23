class SubmitController < ApplicationController
 
  # Action to handle assignment submissions. 
  def new 
    render
  end
 
  # Action to POST the assignment submission to the Leadership Coach.
  def create 
    
    # An array of userInfo objects are stored in the USER_INFOS env var as a JSON string in this format:
    # '{ "brian.sadler@beyondz.org" : {"name" : "Brian Sadler", "coach" : "John Doe", "documentKey" : "0AhkyYmQz77njdHpMeXRpNFUtZHViaWxQMWpfVkpuZmc" }, ... }'

    # This gets the info for the user using their email address as the key
    # IMPORTANT: if this isn't working, check that the ".env" file has the correct info and 
    # is pushed to your environment
    userInfo = JSON.parse(ENV['USER_INFOS'])[params[:userEmail]]

    #BTODO: validate that an object for this email address was found

    # Info on assignment is stored in teh ASSIGNMENT_INFO env var as a JSON string in the following format:
    # { "assignmentId" : "Assignment Display Name", ... }
    assignmentIdToName = JSON.parse(ENV['ASSIGNMENT_INFO'])

    ######### 
    # We're using the google_drive gem.  The API is here: http://gimite.net/doc/google-drive-ruby/
    ########
    
    # You can also use OAuth. See document of GoogleDrive.login_with_oauth for details.
    session = GoogleDrive.login(ENV['GOOGLE_DRIVE_EMAIL'], ENV['GOOGLE_DRIVE_PASSWORD'])
    doc = session.spreadsheet_by_key(userInfo["documentKey"])
    ws = doc.worksheets[0]
   
    # Assuming the worksheet has the following columns, populate it.
    # Student Name  | Student Email  |  Coach  |  Assignment  |   Submission URL  |  Date Submitted  |  Feedback 
    firstEmptyRow = ws.num_rows() + 1
    ws[firstEmptyRow, 1] = userInfo["name"] 
    ws[firstEmptyRow, 2] = params[:userEmail] 
    ws[firstEmptyRow, 3] = userInfo["coach"]  
    ws[firstEmptyRow, 4] = assignmentIdToName[params[:assignment_id]]
    ws[firstEmptyRow, 5] = params[:submissionUrl]
    ws[firstEmptyRow, 6] = Time.now
    ws.save()    

  end

end
