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
      header << 'Override ID (do not change)'

      csv << header

      assignments.each do |a|
        exportable = []
        exportable << a['id']
        exportable << a['course_id']
        exportable << a['name']
        exportable << ''
        exportable << export_date_translation(a['due_at'])
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
            exportable << override['id']

            csv << exportable
          end
        end
      end
    end
  end

  def set_due_dates
    # view render
  end

  def do_set_due_dates
    if params[:import].nil?
      flash[:message] = 'Please upload a csv file'
      redirect_to admin_set_due_dates_path
      return
    end

    file = CSV.parse(params[:import][:csv].read)

    # pre-load the assignments based on the first row
    # If the user followed instructions, this will now
    # match the spreadsheet and preloading will help speed things up.
    main_course_id = file[1][1]
    lms = BeyondZ::LMS.new

    assignments = lms.get_assignments(main_course_id)

    changed = {}

    file.each_with_index do |row, index|
      next if index == 0 # skip the header row

      assignment_id = row[0]
      course_id = row[1]
      due_at = import_date_translation(row[4])
      override_id = row[5]

      # find the original object in the preloaded bit
      assignment = nil
      assignments.each do |a|
        if a['id'].to_s == assignment_id.to_s
          assignment = a
          break
        end
      end

      # This should never happen
      next if assignment.nil?

      if override_id == ''
        # no override id means act on the main object itself
        if assignment['due_at'] != due_at
          assignment['due_at'] = due_at
          changed[assignment_id] = assignment
        end
      else
        # otherwise, we need to find the override and set it
        if assignment['overrides']
          assignment['overrides'].each do |override|
            if override['id'].to_s == override_id
              if override['due_at'] != due_at
                override['due_at'] = due_at
                changed[assignment_id] = assignment
              end
              break
            end
          end
        end
      end
    end

    changed.each do |key, value|
      lms.set_due_dates(value)
    end

    flash[:message] = 'Changes made, you should double check on Canvas now.'
    redirect_to admin_set_due_dates_path
  end

  # This is the date translation when we're importing data
  #
  # So, the string is a date/time in user-friendly format,
  # and it needs to return the full ISO format
  def import_date_translation(date_string)
    if date_string.nil? || date_string.empty?
      return date_string
    end
    # See the format we use below.. includes timezone for user info
    dt = DateTime.strptime("#{date_string}", '%Y-%m-%d %H:%M %Z')
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
