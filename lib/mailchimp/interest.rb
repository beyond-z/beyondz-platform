require 'digest/md5'

module BeyondZ; module Mailchimp
  class Interest
    HOST = "https://us11.api.mailchimp.com"
    VERSION = '3.0'
    
    KEY = Rails.application.secrets.mailchimp_key
    LIST_ID = Rails.application.secrets.mailchimp_list_id
    PRODUCTION_LIST_ID = Rails.application.secrets.production_mailchimp_list_id
    
    class << self
      def groups
        return @groups if defined?(@groups)

        sync_from_production
        @groups = get_groups(LIST_ID)
      end
      
      def sync_from_production
        # return if we are already in production
        return false if in_production?
        
        production_groups = get_groups(PRODUCTION_LIST_ID)
        local_groups = get_groups(LIST_ID)
        
        production_groups.each do |group_name, values|
          # create group locally if needed
          group_id = if local_groups.has_key?(group_name)
            log "found local group #{group_name}"
            local_groups[group_name][:id]
          else
            log "creating local group #{group_name}"
            create_group(group_name)['id']
          end

          values[:options].each do |option_name, option_id|
            # create group option locally if needed
            if local_groups[group_name] && local_groups[group_name][:options].has_key?(option_name)
              log "found local group option #{group_name} -> #{option_name}"
            else
              log "creating local group option #{group_name} -> #{option_name}"
              create_group_option(group_id, option_name)
            end
          end
        end
        
        reset_group_instance_variables
      end
      
      def interests_for user
        interests = {}
        
        # initialize all interests to false
        interest_ids.each{|id| interests[id] = false}
        
        # set location interest, if found
        location_interest = location_interest_for(user)
        interests[location_interest] = true if location_interest
        
        # set recruitment pipeline interest, if found
        pipeline_interest = pipeline_interest_for(user)
        interests[pipeline_interest] = true if pipeline_interest
        
        # set program semester interest, if found
        semester_interest = semester_interest_for(user)
        interests[semester_interest] = true if semester_interest
        
        interests
      end
      
      def interests_by_name interest_ids
        interest_ids.map{|interest_id| interests_by_id[interest_id]}
      end
  
      private
      
      def pipeline_interest_for user
        pipeline_name = case user.class.name
        when 'User'
          case user.applicant_type
          when 'grad_student', 'undergrad_student'
            'Fellow'
          when 'preaccelerator_student'
            'Pre-Accelerator Participant'
          when 'leadership_coach'
            'Leadership Coach'
          when 'event_volunteer'
            'Volunteer'
          when 'professional'
            'Professional Mentor'
          when 'employer'
            'Employer Partner'
          else
            nil
          end
        when 'Champion'
          'Champion'
        else
          nil
        end
        
        return nil if pipeline_name.nil?
        
        groups['Recruitment Pipeline'][:options][pipeline_name]
      end
      
      def location_interest_for user
        region_name = case user.region
        when /chicago/i
          'NLU'
        when /san\s+francisco/i
          'SJSU'
        when /new\s+york|newark/i
          'RUN'
        else
          'No Specific Location'
        end
        
        groups['Location'][:options][region_name]
      end
      
      def semester_interest_for user
        return nil if user.program_semester.nil?
        
        if semester_interest = groups['Semester'][:options][user.program_semester]
          semester_interest
        else
          semester_id = groups['Semester'][:id]
          
          create_group_option(semester_id, user.program_semester)
          reset_group_instance_variables
          
          groups['Semester'][:options][user.program_semester]
        end
      end
      
      def interest_ids
        ids = []
        
        groups.each do |group_name, values|
          ids += values[:options].values
        end
        
        ids
      end
      
      def create_group group_name
        uri = URI("#{HOST}/#{VERSION}/lists/#{LIST_ID}/interest-categories")
        
        data = post(uri, {'title' => group_name, 'type' => 'hidden'})
        
        unless data.has_key?('id')
          error "couldn't create group #{group_name}"
        end
        
        data
      end
      
      def create_group_option group_id, option_name
        uri = URI("#{HOST}/#{VERSION}/lists/#{LIST_ID}/interest-categories/#{group_id}/interests")
        
        data = post(uri, {'name' => option_name})
        
        unless data.has_key?('id')
          error "couldn't create group option #{option_name}"
        end
        
        data
      end
      
      def get_groups list_id
        uri = URI("#{HOST}/#{VERSION}/lists/#{list_id}/interest-categories")
        record = get(uri)
        
        unless record.has_key?('categories')
          error "groups response doesn't contain categories"
          return {}
        end

        groups = {}
        record['categories'].each do |category|
          groups[category['title']] = {
            id: category['id'],
            options: {}
          }
        
          uri = URI("#{HOST}/#{VERSION}/lists/#{list_id}/interest-categories/#{category['id']}/interests")
          interests = get(uri)
          
          unless interests.has_key?('interests')
            error "interests response doesn't contain interests"
            return {}
          end
        
          interests['interests'].each do |interest|
            groups[category['title']][:options][interest['name']] = interest['id']
          end
        end

        groups
      end
      
      def interests_by_id
        return @interests_by_id if defined?(@interests_by_id)
        
        @interests_by_id = {}
        
        get_groups(LIST_ID).each do |category_name, hash|
          hash[:options].each do |interest_name, interest_id|
            @interests_by_id[interest_id] = "#{category_name} - #{interest_name}"
          end
        end
        
        @interests_by_id
      end
    
      def error message, response=nil
        response ||= @last_response
        
        if response && response.methods.include?(:body)
          message += ":\n----\n#{response.body}\n----"
        end
    
        Rails.logger.error("MAILCHIMP: #{message}")
      end
      
      def reset_group_instance_variables
        remove_instance_variable :@groups if defined?(@groups)
        remove_instance_variable :@interests_by_id if defined?(@interests_by_id)
      end
      
      def log message
        Rails.logger.info("MAILCHIMP: #{message}")
      end
      
      def in_production?
        PRODUCTION_LIST_ID.nil? || PRODUCTION_LIST_ID == LIST_ID
      end

      def get uri
        request = Net::HTTP::Get.new(uri)
        request.basic_auth 'key', KEY

        begin
          response = http.request request
          @last_response = response
          
          record = JSON.parse(response.body)
        rescue
          error "interests could not be retrieved"
          raise
        end
      
        record
      end

      def post uri, body
        request = Net::HTTP::Post.new(uri)

        request.basic_auth 'key', KEY
        request.body = body.to_json

        begin
          response = http.request request
          @last_response = response

          record = JSON.parse(response.body)
        rescue
          error "interests could not be posted"
          raise
        end
      
        record
      end
    
      def http
        return @http if defined?(@http)
    
        uri = URI(HOST)

        @http = Net::HTTP.new(uri.host, uri.port)
        @http.use_ssl = true
    
        @http
      end
    end
  end
end; end
