require 'csv'

class Admin::UsersController < Admin::ApplicationController
  def index
    @users = User.all
    respond_to do |format|
      format.html { render }
      format.csv { render text: csv_export }
    end
  end

  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(params[:user].permit(
      :first_name, :last_name, :email, :password))
    @user.skip_confirmation! # admins don't need to confirm new accounts
    @user.save!
    redirect_to admin_users_path
  end

  private

  def csv_export
    CSV.generate do |csv|
      header = Array.new
      header << 'First Name'
      header << 'Last Name'
      header << 'Email'
      header << 'Type'
      header << 'Details'
      header << 'Anticipated Graduation'
      header << 'University Name'
      header << 'Signup Date'
      header << 'Subscribed to Email'
      csv << header
      @users.each do |user|
        exportable = Array.new
        exportable << user.first_name
        exportable << user.last_name
        exportable << user.email
        exportable << user.applicant_type
        exportable << user.applicant_details
        exportable << user.anticipated_graduation
        exportable << user.university_name
        exportable << user.created_at.to_s
        exportable << user.keep_updated
        csv << exportable
      end
    end
  end
end
