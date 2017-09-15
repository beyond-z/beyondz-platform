require 'lms'

class Admin::EventsController < Admin::ApplicationController
  def get_events
    lms = BeyondZ::LMS.new

    @courses = []

    all = lms.get_courses
    all.each do |course|
      @courses << ["#{course['name']} (#{course['id']})", course['id']]
    end
  end

  def download_events
    lms = BeyondZ::LMS.new
    lms.delay.get_events_for_email(params[:email], params[:course][:course_id])
  end

  def set_events
    @user_email = params[:email]
    # view render
  end

  def do_set_events
    if params[:import].nil? || params[:import][:csv].nil?
      flash[:message] = 'Please upload a csv file'
      redirect_to admin_set_events_path(email: '')
      return
    end

    email = params[:import][:email]
    file = CSV.parse(params[:import][:csv].read)

    # pre-load the events based on the first row
    # If the user followed instructions, this will now
    # match the spreadsheet and preloading will help speed things up.
    course_id = file[1][1]
    course_id = course_id["course_".length .. -1]
    lms = BeyondZ::LMS.new

    # this is just too slow.
    events = [] # lms.get_events(course_id)

    changed = {}
    new_count = 0

    begin
      file.each_with_index do |row, index|
        next if index == 0 # skip the header row

        event_id = row[0]
        context_code = row[1]
        parent_event_id = row[2]
        section_name = row[3]
        title = row[4]
        start_at_string = row[5]
        end_at_string = row[6]
        description = row[7]
        location_name = row[8]
        location_address = row[9]

        section_name = section_name.strip unless section_name.nil?
        start_at = import_date_translation(start_at_string, index)
        end_at = import_date_translation(end_at_string, index)

        update_object = {}

        # find the original object in the preloaded bit
        event = nil
        events.each do |a|
          if a['id'].to_s == event_id.to_s
            event = a
            break
          end
        end

        # Gotta bypass this since the get_events is too slow for heroku
        # if event.nil? && !event_id.blank?
          # raise BadEventException, "Row ##{index + 1} has bad Event ID #{event_id}. Double check it on Canvas."
        # end

        if event_id.blank?
          # new section
          section_object = lms.get_section_by_name(course_id, section_name, false)
          if section_object.nil?
            raise BadSectionNameException, "Row ##{index + 1} has bad Section Name #{section_name}. Double check it on Canvas. These need to match exactly."
          end
          events.each do |o|
              if o['context_code'] == "course_section_#{section_object['id']}" && o['parent_event_id'] == parent_event_id
                raise DuplicateSectionNameException, "Row ##{index + 1} claims to create a new event for #{section_name}, but a row already exists for that section. Duplicates are not allowed and will confuse Canvas. The section ID column if you want to edit the existing row ought to be #{o['id']}"
              end
          end

          update_object["event_id"] = nil
          update_object["context_code"] = "course_section_#{section_object['id']}"
          update_object["parent_event_id"] = parent_event_id
          update_object["title"] = title
          update_object["start_at"] = start_at
          update_object["end_at"] = end_at
          update_object["description"] = description
          update_object["location_name"] = location_name
          update_object["location_address"] = location_address

          changed["new_#{new_count}"] = update_object
          new_count += 1
        else
          update_object["event_id"] = event_id
          # I have to bypass the partial object updates because, ironically, loading the
          # old event for comparison is too slow on heroku :(
          update_object["title"] = title # if title != event["title"]
          update_object["description"] = description # if description != event["description"]
          update_object["location_name"] = location_name # if location_name != event["location_name"]
          update_object["location_address"] = location_address # if location_address != event["location_address"]
          update_object["start_at"] = start_at if start_at_string # != lms.export_date_translation(event["start_at"])
          update_object["end_at"] = end_at if end_at_string # != lms.export_date_translation(event["end_at"])

          if update_object.keys.length > 1
            changed[event_id] = update_object
          end
        end
      end
    rescue BadDateException => e
      flash[:error] = "#{e.message} is in the wrong format."
      flash[:message] = 'Please write dates and times in format YYYY-MM-DD HH:MM ZZZ. For example, "2015-12-25 12:00 EST" means noon in Eastern time on Christmas 2015.'
      redirect_to admin_set_events_path(email: email)
      return
    rescue BadEventException => e
      flash[:error] = "#{e.message}"
      flash[:message] = 'Go to the event you want on Canvas. At the end of the URL there will be a number like /events/21. The event ID there would be 21.'
      redirect_to admin_set_events_path(email: email)
      return
    rescue DuplicateSectionNameException => e
      flash[:error] = "#{e.message}"
      flash[:message] = 'Make sure each cohort only appears once per event. You might want to get a fresh export of the spreadsheet to sync with Canvas and then make your edits on that.'
      redirect_to admin_set_events_path(email: email)
      return
    rescue BadSectionNameException => e
      flash[:error] = "#{e.message}"
      flash[:message] = 'Make sure the cohort name in the row is an exact match. Also double-check the event ID and course ID columns. If this is supposed to be a new override, also make sure you remembered to clear out the override ID column too (and if it is supposed to edit an existing one, be sure that value is left the same from the export). Any given section should only appear once per event.'
      redirect_to admin_set_events_path(email: email)
      return
    end

    lms = BeyondZ::LMS.new
    lms.delay.commit_new_events(email, changed)

    flash[:message] = 'Changes in progress, you should check your email to know when it is complete.'
    redirect_to admin_set_events_path(email: email)
  end

  # This is the date translation when we're importing data
  #
  # So, the string is a date/time in user-friendly format,
  # and it needs to return the full ISO format
  def import_date_translation(date_string, informational_row)
    if date_string.nil? || date_string.empty?
      return date_string
    end
    # See the format we use below.. includes timezone for user info, but as
    # just PT, ET, etc. We need to transform those into PST, EST. So it will
    # cut whitespace then insert the S right at the end...
    date_string = date_string.strip.insert(-2, 'S')
    begin
      # ....yielding a valid %Z specifier such as PST
      dt = DateTime.strptime("#{date_string}", '%Y-%m-%d %H:%M %Z')
      # switching to a TZ that observes DST for the next check
      time_test = dt.to_time.in_time_zone('America/New_York')
      # Now, if the date in there (the to_time converts it to an actual time btw)
      # is in DST, then we need to fall back because it was uploaded in ST but
      # should be in DT (which will spring it forward a bit, so the minus balances)
      dt -= 1.hour if time_test.dst?
    rescue ArgumentError
      raise BadDateException, "Row ##{informational_row + 1} with date \"#{date_string}\""
    end
    dt.utc.iso8601 # do the utc conversion on our end to ensure canvas doesn't try to
  end
end

class BadDateException < Exception
end

class BadEventException < Exception
end

class BadSectionNameException < Exception
end

class DuplicateSectionNameException < Exception
end

