class CommentsController < ApplicationController
  def create
    comment = params[:comment].permit(:task_id, :content)
    comment[:user_id] = current_user.id
    if @comment = Comment.create(comment)
      respond_to do |format|
        format.html { redirect_to :back }
        format.json { render json: { success: true, id: @comment.id } }
      end
    end
  end
end
