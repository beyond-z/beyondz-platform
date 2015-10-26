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
        exportable << a['due_at']
        exportable << ''

        csv << exportable

        if a['overrides']
          a['overrides'].each do |override|
            exportable = []
            exportable << a['id']
            exportable << a['course_id']
            exportable << a['name']
            exportable << override['title']
            exportable << override['due_at']
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
      due_at = row[4]
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
end
