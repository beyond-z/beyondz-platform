class FeedbackController < ApplicationController
  def gather
    if request.post?
      f = Feedback
      f.feedback(params[:email], params[:message]).deliver
      flash[:message] = "Thank you for your feedback! It's people like you that help make the Beyond Z experience great."
      redirect_to "/"
    end
  end
end
