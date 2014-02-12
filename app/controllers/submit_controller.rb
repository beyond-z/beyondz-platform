class SubmitController < ApplicationController
 
  # Action to handle assignment submissions. 
  def new 
    render
  end
 
  # Action to POST the assignment submission to the Leadership Coach.
  def create 
          
    #BTODO: move username/password to config files so they aren't checked into source ctrl

    # You can also use OAuth. See document of
    # GoogleDrive.login_with_oauth for details.
    session = GoogleDrive.login("myemail@gmail.com", "myPassword")

    ws = session.spreadsheet_by_title('TestAssignmentSubmit').worksheets[0]

    # Changes content of cells.
    # Changes are not sent to the server until you call ws.save().
    ws[2, 1] = "foo"
    ws[2, 2] = "bar"
    ws.save()    

  end

end
