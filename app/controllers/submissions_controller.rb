class SubmissionsController < ApplicationController
  def index
    @submissions = Submission.for_assignment(params[:assignment_id])

    @submission = Submission.new
  end

  def update
    submission = Submission.find(params[:id])
    submission.updated_at = Time.now

    # handle different submission types
    if params[:submission][:files]
      if submission.files.present?
        submission.files.first.update_attribute(
          submission.file_type =>
            params[:submission][:files][submission.file_type.to_sym])
      else
        submission.files << SubmissionFile.create(
          submission_definition_id: submission.submission_definition.id,
          submission_id: submission.id,
          submission.file_type =>
            params[:submission][:files][submission.file_type.to_sym]
        )
      end
    end
    submission.save!

    redirect_to assignment_submissions_path(params[:assignment_id])
  end
end
