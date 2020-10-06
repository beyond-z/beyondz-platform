require 'csv'
require 'zlib'

module BeyondZ
  # this is a helper for the user export
  # it was too slow to do directly so i had
  # to move it to a helper lib
  class SheetsExport

    public

    def users_csv(email)
      @users = User.order(:last_name)
      csv_content = CSV.generate do |csv|
        csv << csv_export_header
        @users.each do |user|
          exportable = []

          exportable << user.id
          exportable << user.first_name
          exportable << user.last_name
          exportable << user.email
          exportable << user.relationship_manager
          exportable << !user.relationship_manager?
          exportable << user.days_since_last_activity
          exportable << user.exclude_from_reporting
          exportable << user.active_status
          exportable << user.applicant_type
          exportable << user.applicant_details
          exportable << user.anticipated_graduation
          exportable << user.started_college_in
          exportable << user.university_name
          exportable << user.bz_region
          exportable << user.profession
          exportable << user.company
          exportable << user.city
          exportable << user.state
          exportable << user.like_to_know_when_program_starts
          exportable << user.like_to_help_set_up_program
          exportable << user.applicant_comments
          exportable << user.created_at.to_s
          exportable << user.last_sign_in_at.to_s
          exportable << user.external_referral_url
          exportable << user.internal_referral_url
          exportable << user.associated_program

          if user.enrollment
            e = user.enrollment
            e.attributes.values_at(*Enrollment.column_names).each do |v|
              exportable << v
            end

            if e.resume.present?
              exportable << e.resume.url
            else
              exportable << '<none uploaded>'
            end
          end

          csv << exportable
        end
      end

      attachment_content = csv_content

      StaffNotifications.requested_spreadsheet_ready(email, "users.csv", attachment_content).deliver
    end

    def users_xls(email)
      @users = User.order(:last_name)
      attachment_content = @users.to_xls

      StaffNotifications.requested_spreadsheet_ready(email, "users.xls", attachment_content).deliver
    end

    def applications_csv(email)
      @enrollments = Enrollment.all

      csv_content = CSV.generate do |csv|
        header = *Enrollment.column_names
        header << 'Uploaded Resume'
        csv << header
        @enrollments.each do |e|
          exportable = e.attributes.values_at(*Enrollment.column_names)
          if e.resume.present?
            exportable << e.resume.url
          else
            exportable << '<none uploaded>'
          end
          csv << exportable
        end
      end

      attachment_content = csv_content
      StaffNotifications.requested_spreadsheet_ready(email, "applications.csv", attachment_content).deliver
    end

    def applications_xls(email)
      @enrollments = Enrollment.all

      attachment_content = @enrollments.to_xls
      StaffNotifications.requested_spreadsheet_ready(email, "applications.xls", attachment_content).deliver
    end

    def csv_export_header
      header = []
      header << 'User ID'
      header << 'First Name'
      header << 'Last Name'
      header << 'Email'
      header << 'Relationship Manager (owner)'
      header << 'New User'
      header << 'Days Since Last Activity'
      header << 'Exclude from reporting'
      header << 'Active Status'
      header << 'Applicant type'
      header << 'Type = other'
      header << 'Anticipated Graduation'
      header << 'Started College In'
      header << 'University Name'
      header << 'Braven Region(s)'
      header << 'Profession/Title/Industry'
      header << 'Company'
      header << 'City'
      header << 'State'
      header << 'Like to know when BV starts program'
      header << 'Like to help BV start'
      header << 'User-provided comments'
      header << 'Signup Date'
      header << 'Last sign in at'
      header << 'Came from to reach site'
      header << 'Came from to reach sign up form'
      header << 'Associated Program'

      Enrollment.column_names.each do |cn|
        header << cn
      end

      header << 'Resume URL'

      header
    end

  end
end
