require 'lms'

class Admin::AssignmentsController < Admin::ApplicationController
  def get_due_dates
    lms = BeyondZ::LMS.new

    @courses = []
    
    all = lms.get_courses
    all.each do |course|
      @courses << ["#{course['name']} (#{course['id']})", course['id']]
    end
  end

  def download_due_dates
    lms = BeyondZ::LMS.new

    assignments = lms.get_assignments(params[:course][:course_id])

    respond_to do |format|
      format.csv do
        response.headers['Content-Disposition'] = 'attachment; filename="assignment_due_dates.csv"'
        render text: csv_due_date_export(assignments)
      end
    end
  end

  def csv_due_date_export(assignments)
    CSV.generate do |csv|
      header = []
      header << 'Assignment ID (do not change)'
      header << 'Course ID (do not change)'
      header << 'Name'
      header << 'Section Name'
      header << 'Due Date'
      header << 'Until'
      header << 'Override ID (do not change, but leave blank for new section)'

      csv << header

      assignments.each do |a|
        exportable = []
        exportable << a['id']
        exportable << a['course_id']
        exportable << a['name']
        exportable << ''
        exportable << export_date_translation(a['due_at'])
        exportable << export_date_translation(a['lock_at'])
        exportable << ''

        csv << exportable

        if a['overrides']
          a['overrides'].each do |override|
            exportable = []
            exportable << a['id']
            exportable << a['course_id']
            exportable << a['name']
            exportable << override['title']
            exportable << export_date_translation(override['due_at'])
            exportable << export_date_translation(override['lock_at'])
            exportable << override['id']

            csv << exportable
          end
        end
      end
    end
  end

  def set_due_dates
    @user_email = params[:email]
    # view render
  end

  def do_set_due_dates
    if params[:import].nil?
      flash[:message] = 'Please upload a csv file'
      redirect_to admin_set_due_dates_path(email: email)
      return
    end

    email = params[:import][:email]
    file = CSV.parse(params[:import][:csv].read)

    # pre-load the assignments based on the first row
    # If the user followed instructions, this will now
    # match the spreadsheet and preloading will help speed things up.
    main_course_id = file[1][1]
    lms = BeyondZ::LMS.new

    assignments = lms.get_assignments(main_course_id)

    changed = {}

    begin
      file.each_with_index do |row, index|
        next if index == 0 # skip the header row

        assignment_id = row[0]
        course_id = row[1]
        section_name = row[3]
        due_at_str = row[4]
        due_at = import_date_translation(row[4], index)
        lock_at_str = row[5]
        lock_at = import_date_translation(row[5], index)
        override_id = row[6]

        # find the original object in the preloaded bit
        assignment = nil
        assignments.each do |a|
          if a['id'].to_s == assignment_id.to_s
            assignment = a
            break
          end
        end

        if assignment.nil?
          raise BadAssignmentException, "Row ##{index} has bad Assignment ID #{assignment_id}. Double check it on Canvas."
        end

        if override_id.nil? || override_id == ''
          if section_name.nil? || section_name.empty?
            # no override id and no section name means act on the main object itself
            #
            # It compares what *would* be exported with what the user wrote
            # on the string level to better check for unchanged rows because
            # the timezone adjustment can cause the basic comparison to fail
            # despite them referring to the same thing once saved.
            # (Basically "9:00 PST" != "12:00 GMT" on this level, so we want
            #  to convert them both to export format so we know that will match.)
            if export_date_translation(assignment['due_at']) != due_at_str
              assignment['due_at'] = due_at
              changed[assignment_id] = assignment
            end
            if export_date_translation(assignment['lock_at']) != lock_at_str
              assignment['lock_at'] = lock_at
              changed[assignment_id] = assignment
            end
          else
            # Otherwise, an existing section name but no override ID
            # means we need to create a new override.
            override = {}
            section_object = lms.get_section_by_name(course_id, section_name, false)
            if section_object.nil?
              raise BadSectionNameException, "Row ##{index} has bad Section Name #{section_name}. Double check it on Canvas. These need to match exactly."
            end
            override['course_section_id'] = section_object['id']
            override['due_at'] = due_at
            override['lock_at'] = lock_at

            if assignment['overrides'].nil?
              assignment['overrides'] = []
            end

            assignment['overrides'].each do |override|
              if override['title'] == section_name
                raise DuplicateSectionNameException, "Row ##{index} claims to create a new due date for #{section_name}, but a row already exists for that section. Duplicates are not allowed and will confuse Canvas. The section ID column if you want to edit the existing row ought to be #{override['id']}"
              end
            end


            assignment['overrides'] << override
            changed[assignment_id] = assignment
          end
        else
          # otherwise, we need to find the override and set it
          found_override = false
          found_override_name = ''
          if assignment['overrides']
            assignment['overrides'].each do |override|
              if override['id'].to_s == override_id
                # Ditto on the string note as above
                if export_date_translation(override['due_at']) != due_at_str
                  override['due_at'] = due_at
                  changed[assignment_id] = assignment
                end
                if export_date_translation(override['lock_at']) != lock_at_str
                  override['lock_at'] = lock_at
                  changed[assignment_id] = assignment
                end
                found_override = true
                found_override_name = override['title']
                break
              end
            end
          end

          if !found_override
            raise BadSectionNameException, "Row ##{index} claims to edit #{override_id}, but Canvas doesn't think that exists. You might want to re-export and be careful not to exit the override ID column for rows that already exist."
          end
          
          if found_override && found_override_name != section_name
            raise BadSectionNameException, "Row ##{index} claims to edit #{override_id}, but the spreadsheet listed #{section_name} as the section name, and Canvas thinks it is supposed to be #{found_override_name}. You might have made a mistake copy/pasting an existing row. You want to change the section name, then clear out the override id column for a new row."
          end
        end
      end
    rescue BadDateException => e
      flash[:error] = "#{e.message} is in the wrong format."
      flash[:message] = 'Please write dates and times in format YYYY-MM-DD HH:MM ZZZ. For example, "2015-12-25 12:00 EST" means noon in Eastern time on Christmas 2015.'
      redirect_to admin_set_due_dates_path(email: email)
      return
    rescue BadAssignmentException => e
      flash[:error] = "#{e.message}"
      flash[:message] = 'Go to the assignment you want on Canvas. At the end of the URL there will be a number like /assignments/21. The assignment ID there would be 21.'
      redirect_to admin_set_due_dates_path(email: email)
      return
    rescue DuplicateSectionNameException => e
      flash[:error] = "#{e.message}"
      flash[:message] = 'Make sure each cohort only appears once per assignment. You might want to get a fresh export of the spreadsheet to sync with Canvas and then make your edits on that.'
      redirect_to admin_set_due_dates_path(email: email)
      return
    rescue BadSectionNameException => e
      flash[:error] = "#{e.message}"
      flash[:message] = 'Make sure the cohort name in the row is an exact match. Also double-check the assignment ID and course ID columns. If this is supposed to be a new override, also make sure you remembered to clear out the override ID column too (and if it is supposed to edit an existing one, be sure that value is left the same from the export). Any given section should only appear once per assignment.'
      redirect_to admin_set_due_dates_path(email: email)
      return
    end

    self.delay.commit_new_due_dates(email, changed)

    flash[:message] = 'Changes in progress, you should check your email to know when it is complete.'
    redirect_to admin_set_due_dates_path(email: email)
  end

  def commit_new_due_dates(email, changed)
    lms = BeyondZ::LMS.new
    changed.each do |key, value|
      lms.set_due_dates(value)
    end
    StaffNotifications.canvas_due_dates_updated(email).deliver
  end

  # This is the date translation when we're importing data
  #
  # So, the string is a date/time in user-friendly format,
  # and it needs to return the full ISO format
  def import_date_translation(date_string, informational_row)
    if date_string.nil? || date_string.empty?
      return date_string
    end
    # See the format we use below.. includes timezone for user info
    begin
      dt = DateTime.strptime("#{date_string}", '%Y-%m-%d %H:%M %Z')
    rescue ArgumentError
      raise BadDateException, "Row ##{informational_row+1} with date \"#{date_string}\""
    end
    dt.iso8601
  end

  # This is the translation when we're exporting from Canvas.
  #
  # So it gives us the ISO format, and needs to return a user-
  # friendly format in a user-friendly timezone.
  def export_date_translation(date_string)
    if date_string.nil? || date_string.empty?
      return date_string
    end
    raise date_string
    dt = DateTime.iso8601(date_string)
    # Best guess for friendly timezone... using the city means
    # the library will handle stuff like DST... for now though.
    # The Canvas course API doesn't export the TZ setting, and even if
    # it did, Rails likes the city name rather than the offset so... i think
    # this will be best we can for now.
    #
    # Pacific time is the latest TZ in the US, so if it is set to end of day there
    # at least the date will always be right in Eastern time too.
    #
    # It will print the tz in the string for the user to read and even modify.
    dt = dt.in_time_zone('America/Los_Angeles')
    dt.strftime('%Y-%m-%d %H:%M %Z')
  end
end

class BadDateException < Exception

end

class BadAssignmentException < Exception

end

class BadSectionNameException < Exception

end

class DuplicateSectionNameException < Exception

end
