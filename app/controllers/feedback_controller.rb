class FeedbackController < ApplicationController
  def gather
    if request.post?
      f = Feedback
      f.feedback(params[:email], params[:message]).deliver
      flash[:message] = "Thank you for your feedback!"
      redirect_to "/"
    end
  end
end
