class CommentsController < ApplicationController
  def create
    comment = params[:comment].permit(:task_id, :content, :document, :image)
    comment[:user_id] = current_user.id
    # get file types used in form
    file_types = comment.keys.select { |k| [:document, :image].include?(k.to_sym) }
    # use first passed file type (only active one is passed)
    comment[:file_type] = file_types.first

    @comment = Comment.create(comment)
    respond_to do |format|
      format.html { redirect_to :back }
      format.json { render json: { success: true, id: @comment.id } }
    end
  end
end
