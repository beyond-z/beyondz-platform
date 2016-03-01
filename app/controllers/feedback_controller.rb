class FeedbackController < ApplicationController
  def new
    @back_to = request.referrer
  end

  def create
    f = Feedback
    f.feedback(params[:email], params[:message]).deliver
    flash[:message] = "Thank you for your feedback! It's people like you that help make the Braven experience great."
    redirect_to params[:back_to]
  end
end
