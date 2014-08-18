# This file should contain all the record creation needed to seed the database
# with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db
# with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

user = User.new(email: 'test+student1@beyondz.org', password: 'test', first_name: 'BeyondZ', last_name: 'Test')
user2 = User.new(email: 'test+student2@beyondz.org', password: 'test', first_name: 'Second', last_name: 'Student')
coach = User.new(email: 'test+coach1@beyondz.org', password: 'test', first_name: 'BeyondZ', last_name: 'Coach')
admin_user = User.new(email: 'test+admin@beyondz.org', password: 'test', first_name: 'BeyondZ', last_name: 'Admin', is_administrator: true)

user.skip_confirmation!
user2.skip_confirmation!
coach.skip_confirmation!
admin_user.skip_confirmation!

user.save!
user2.save!
coach.save!
admin_user.save!

CoachStudent.create(coach_id: coach.id, student_id: user.id)
CoachStudent.create(coach_id: coach.id, student_id: user2.id)

# Task Modules
text_module = TaskModule.create(name: 'Text', code: 'text')
compare_module = TaskModule.create(name: 'Compare and Rank', code: 'compare_and_rank')
resume_builder_module = TaskModule.create(name: 'Résumé Builder', code: 'resume_builder')
video_quiz_module = TaskModule.create(name: 'Video Quiz', code: 'video_quiz')
file_upload_module = TaskModule.create(name: 'File Upload', code: 'file_upload')

# Assignment imports from the existing HTML
item = AssignmentDefinition.new
item.front_page_info = "
          <h3>You will get practice this week:</h3>
          <ul>
            <li><strong>Purpose:</strong> Set the tone for the program.  Inspire students to dream big and to define for themselves what it means for them to go Beyond Z.  Build shared vocabulary.  Surface ideas/understanding from participants about leadership.</li>
            <li><strong>Personal Assets:</strong> Begin to identify personal assets and the assets in the cohort/BZ community.</li>
            <li><strong>Networks:</strong> Begin to build a sense of team and community.</li>
            <li><strong>Seven Generations:</strong> Explain the concept of Seven Generations, be deeply motivated by it and begin to understand one&#8217;s place in it.</li>
            <li><strong>Organization &amp; Prioritization:</strong> Explore Beyond Z platform. Set-up Google Drive Account for assignments.</li>
          </ul>
        "
item.title = 'Weekend 0 Launch: The Story of Self and Us'
item.led_by = 'Staff'
item.assignment_download_url = 'https://docs.google.com/a/beyondz.org/forms/d/1cgwwrGn3ZMNkrKvL-Uj4FNz1Qf27xPc6usqse7fTWBg/viewform'
item.start_date = Time.parse('Feb 28')
item.end_date = Time.parse('Mar 1')
item.seo_name = 'story-of-self'
item.save
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1, requires_approval: true,
    name: 'Take Myers Briggs Personality Test',
    details: 'Take this test: <a href="http://www.humanmetrics.com/cgi-win/JTypes1.htm">Take Myers Briggs Personality Test</a>'
  )
)

task_definition = TaskDefinition.create(
  required: true, position: 2, requires_approval: true,
  name: 'Compass Exercise',
  details: 'Go through the <a href="http://www.nsrfharmony.org/protocol/doc/north_south.pdf\">Compass Exercise</a> and pick a direction that represents you.'
  
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: text_module.id,
    position: 1,
    configuration: {question: 'Which direction represents you?'}.to_json
  )
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: text_module.id,
    position: 2,
    configuration: {question: 'Why?'}.to_json
  )
)
item.task_definitions.push(task_definition)

task_definition = TaskDefinition.create(
  required: true, position: 3,
  requires_approval: true, name: 'Personality Assessment Results',
  summary: 'Upload the results of the Myers Briggs Personality Test.',
  details: 'Upload the <a href="https://docs.google.com/a/beyondz.org/forms/d/1cgwwrGn3ZMNkrKvL-Uj4FNz1Qf27xPc6usqse7fTWBg/viewform">personality assessment results </a> by the end of Weekend 0.'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: file_upload_module.id,
    position: 1,
    file_type: 'document'
  )
)
item.task_definitions.push(task_definition)

task_definition = TaskDefinition.create(
  required: true, position: 4,
  name: 'Watch Story of Self',
  summary: 'Discover your story!'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: video_quiz_module.id,
    introduction: 'Watch this video (40 min) and answer the questions.',
    configuration: {
      youtube_id: 'Obiztwn2oEU',
      start_time: '12:55',
      items: [
        {
          time: '13:00',
          question: 'Challenge or outcome?',
          fields: [
            {
              name: 'some_field',
              type: :textarea,
            }
          ]
        },
        {
          time: '13:05',
          question: 'Quiz 2 can be different',
          fields: [
            {
              name: 'another_field',
              type: :textarea,
            },
            {
              name: 'yet_another_field',
              type: 'select',
              options: ['Choice 1', 'Choice 2']
            }
          ]
        }
      ]
    }.to_json
  )
)
item.task_definitions.push(task_definition)

item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 5, requires_approval: true,
    name: 'Beyond Z College Survey',
    details: 'Complete the <a href="https://docs.google.com/forms/d/10JAYX6qwuZ_z9ZXooZ_QsXmCWhGeLtsTFqIUKz6blp4/viewform">Beyond Z College Survey</a> <em>(15 min)</em>.'
  )
)
item.save

item = AssignmentDefinition.new
item.front_page_info = "
          <h3>You will get practice this week:</h3>
          <ul>
            <li><strong>Personal Assets and Networks:</strong> Identify and explore assets, passions and networks that can connect them to potential summer opportunities and beyond.</li>
            <li><strong>Organization and Prioritization:</strong> Inventory assets and research what jobs/career paths might allow them to follow their interests.</li>
            <li><strong>Networks:</strong> Identify the members of participant networks who provide key supports.</li>
          </ul>
        "
item.title = "Week 1: Exploring Your Passions and Professions"
item.led_by = "Coach"
item.assignment_download_url = "assignments/passions-professions/submissions/new"
item.start_date = Time.parse("Mar 3")
item.end_date = Time.parse("Mar 9")
item.seo_name = "passions-professions"
item.save
task_definition = TaskDefinition.create(
  required: true, position: 1, requires_approval: true,
  name: 'Attend the group session'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: text_module.id,
    configuration: {question: 'What are your thoughts after the session?'}.to_json
  )
)
item.task_definitions.push(task_definition)
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 2, requires_approval: true,
    name: 'Request informational interview',
    summary: 'Request at least one informational interview to explore summer opportunities and/or career majors.'
  )
)

task_definition = TaskDefinition.create(
  required: true, position: 3, requires_approval: true,
  name: 'Evidence of Applied Learning',
  details: 'Complete and upload <a href="https://www.dropbox.com/s/5kolp0reqiyon8k/F%20%20Week%201_Exploring%20Passions%20and%20Professions.docx?dl=1">Evidence of Applied Learning (EAL)</a> (by 9 PM, Friday, March 14th).'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: file_upload_module.id,
    file_type: 'document'
  )
)
item.task_definitions.push(task_definition)
item.save

item = AssignmentDefinition.new
item.front_page_info = "
          <h3>You will get practice this week:</h3>
          <ul>
            <li>Researching &amp; writing cover letters that connect with potential internship supervisors.</li>
            <li><strong>NOTE: This is a 2-part module that asks you to write a Résumé and a Cover Letter, spending a total of 3 hours across both assignments.</strong></li>
          </ul>
        "
item.title = 'Week 2(a): Cover Letter'
item.led_by = 'Peer'
item.assignment_download_url = 'assignments/cover-letter/submissions/new'
item.start_date = Time.parse('Mar 10')
item.end_date = Time.parse('Mar 16')
item.seo_name = 'cover-letter'
item.save
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1,
    name: 'Learn about cover letters',
    summary: 'Get the lowdown on cover letters and prepare to write your own.',
    details: 'Read <a href="http://www.slate.com/articles/business/moneybox/2013/08/cover_letter_writing_advice_how_to_write_a_cover_letter_for_an_entry_level.html">I&#8217;ve Read 500 Cover Letters for Entry Level Media Jobs</a> and <a href="http://www.fastcompany.com/3016727/leadership-now/dont-be-boring-how-to-write-a-cover-letter-that-can-get-you-the-job">Don&#8217;t Be Boring: How to Write a Cover Letter That Can Get You the Job</a>'
  )
)
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 2, requires_approval: true,
    name: 'Draft Cover Letter',
    summary: 'Put together your own cover letter.'
  )
)

task_definition = TaskDefinition.create(
  required: true, position: 3,
  requires_approval: true, name: 'Cover Letter',
  details: 'Submit Cover Letter and complete Evidence of Applied Learning (EAL) by 9 PM Friday, March 21.'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: file_upload_module.id,
    file_type: 'document'
  )
)
item.task_definitions.push(task_definition)
item.save

item = AssignmentDefinition.new
item.front_page_info = "
    <h3>You will get practice this week:</h3>
    <ul>
      <li>Emphasizing your assets as you write your résumé.</li>
      <li>Practice giving feedback on another college participant&#8217;s résumé.</li>
      <li>Finding summer internships and tailoring your résumé to different opportunities that you identify.</li>
      <li><strong>NOTE: This is a 2-part module that asks you to write a résumé and a Cover Letter, spending a total of 3 hours across both artifacts.</strong></li>
    </ul>
  "
item.title = 'Week 2(b): Résumé'
item.led_by = 'Peer'
item.assignment_download_url = 'assignments/resume/submissions/new'
item.start_date = Time.parse('Mar 10')
item.end_date = Time.parse('Mar 16')
item.seo_name = 'resume'
item.save

item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1,
    name: 'Parts of a résumé',
    details: '<p>But before you rank résumés, we go to unpack the basic
      building blocks of a résumé and discuss what makes a good résumé.</p>

      <object width="560" height="315">
        <param name="movie" value="' + ("/videos/Interactive_Resume_Parts_Video.swf") + '" />
        <embed src="' + ("/videos/Interactive_Resume_Parts_Video.swf") + '" width="560" height="315"></embed>
      </object>
    '
  )
)

item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 2,
    name: 'Ranking Matrix',
    details: '
      <p>
        Take a look at the components of an effective resume and check out this
        rubric to assess resume quality along the 4 different parts. After you
        finish reviewing this rubric, you\'ll review 3 actual student resumes
        and rank them based on how well you think they did.
      </p>
      <table class="matrix-table">
        <thead>
          <th style="font-size: 2em;">Category</th>
          <th>
            <span style="font-size: 1.5em;">1</span><br />
            Goes into trash
          </th>
          <th>
            <span style="font-size: 1.5em;">2</span><br />
            Middle of the stack
          </th>
          <th>
            <span style="font-size: 1.5em;">3</span><br />
            Scores interview or callback
          </th>
        </thead>
        <tr>
          <td style="font-weight: bold;">Format</td>
          <td>
            <ul>
              <li>This résumé is either one-half page or 2-3 pgs.</li>
              <li>Font is too big or hard to read.</li>
              <li>More white space than words.</li>
              <li>Multiple spelling and/or grammar errors.</li>
            </ul>
          </td>
          <td>
            <ul>
              <li>The font and spacing of this résumé are not appealing and
                cannot be easily scanned.</li>
              <li>There are a few spelling errors and grammatical mistakes.</li>
            </ul>
          </td>
          <td>
            <ul>
              <li>This résumé fills the page but is not overcrowded.</li>
              <li>There are no grammar or spelling errors.</li>
              <li>Easily scanned.</li>
            </ul>
          </td>
        </tr>
        <tr>
          <td style="font-weight: bold;">Education Section</td>
          <td>
            <ul>
              <li>This section is missing crucial information. Ex: Institution
                is listed, but not its location and graduation.</li>
              <li>Major is included, but not degree.</li>
              <li>No GPA.</li>
            </ul>
          </td>
          <td>
            <ul>
              <li>Information such as institution and its location, graduation
                date, and major are included, but degree and GPA are not listed.</li>
              <li>This section is not well organized and there is no order to how
                information is formatted.</li>
            </ul>
          </td>
          <td>
            <ul>
              <li>Section is organized, clear, and well defined.</li>
              <li>It includes: institution and its location, graduation date,
                major, degree, GPA, study abroad (as appropriate), and any
                relevant course work.</li>
            </ul>
          </td>
        </tr>
        <tr>
          <td style="font-weight: bold;">Experience Section</td>
          <td>
            <ul>
              <li>There is no order to the position descriptions.</li>
              <li>Descriptions are not detailed and don\'t illustrate the
                experience.</li>
              <li>No locations and dates of employment are listed.</li>
            </ul>
          </td>
          <td>
            <ul>
              <li>Descriptions are not presented in bulleted lists that begin with
                strong action verbs.</li>
              <li>Passive voice structure is used instead of active voice.</li>
              <li>Specific details and numbers are missing describe
                achievements.</li>
              <li>Places of work are included for each position, but not
                locations, dates, and titles.</li>
            </ul> 
          </td>
          <td>
            <ul>
              <li>This section is well defined, and information relates to the
                intended career field.</li>
              <li>Strong action verbs used along with concrete details.</li>
              <li>Places of work, location, titles, and dates are included for
                each position.</li>
              <li>Descriptions are clear and formatted as bullets beginning
                with action verbs.</li>
            </ul>
          </td>
        </tr>
        <tr>
          <td style="font-weight: bold;">Leadership Section</td>
          <td>
            <ul>
              <li>This section is missing—or contains very little—information.</li>
              <li>Organization titles or dates of involvement are not included,
                and there are no descriptions.</li>
            </ul>
          </td>
          <td>
            <ul>
              <li>This section is missing key information such as leadership
                positions held or dates of involvement.</li>
            </ul>
          </td>
          <td>
            <ul>
              <li>This section lists clearly leadership skills and date of
                involvement.</li>
            </ul>
          </td>
        </tr>
        <tr>
          <td style="font-weight: bold;">Skills and Interests Section</div>
          <td>
            <ul>
              <li>Does not include any skills, courses or experiences.</li>
            </ul>
          </td>
          <td>
            <ul>
              <li>Some events are listed, but not clear and missing gaps.</li>
            </ul>
          </td>
          <td>
            <ul>
              <li>Skills and honors listed clearly with bulleted details provided.</li>
            </ul>
          </td>
        </tr>
      </table>
      '
  )
)

item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 3,
    name: 'Your résumé',
    details: '<p>Your résumé is the crown jewel of your career portfolio. Just
      like companies have logos and "brand reputations" where they are publicly
      known for certain things, a résumé reflects your own personal brand and
      represents what you stand for as a leader and as a professional. It\'s one
      of the most important professional documents that represents you.</p>
      <p>A good résumé will help you to open doors to interviews for competitive
      internships and job opportunities. Your objective in crafting a résumé is
      to set yourself apart from hundreds or thousands of other candidates and
      position yourself as a unique candidate.</p>
      <p>We’re going to meet Alex, Eric, and Amanda. They are all sophomore
      students at UC Berkeley and are competing for the same summer internship
      in education in DC over the summer and have all created their résumés.
      Based on their résumés, we\'re going to have you predict which one has the
      best shot and scoring an interview.</p>
      
      <object width="560" height="315">
        <param name="movie" value="' + ("/videos/Interactive_Resume_Louis_Amanda_Eric_Intro_Video.swf") + '" />
        <embed src="' + ("/videos/Interactive_Resume_Louis_Amanda_Eric_Intro_Video.swf") + '" width="560" height="315"></embed>
      </object>
      '
  )
)

task_definition = TaskDefinition.create(
  required: true, position: 4, name: 'Rank the résumés',
  summary: 'Determine which résumés are the strongest and weakest.',
  details: '<p>Take a look at Louis\', Eric\'s and Amanda\'s resumes and consider
    their impact. How well do they do in terms of overall formatting? What
    details do they include in their education? Do they use strong action verbs
    to describe their experience and leadership? Do they include skills and
    interests that round them out? Refer back to the resume rubric!</p>'
  )
task_definition.sections.push(
  TaskSection.create(
    task_module_id: compare_module.id,
    introduction: 'View each résumé and rate them below.',
    configuration: {
      item_label: 'Résumé',
      items: [
        {
          label: "Louis' Résumé",
          content: '
            <div style="font-family: georgia; padding: 5em;">
              <section>
                <div class="col-sm-12 text-center">
                  <strong>Louis Smith</strong><br />
                  Louissmith@berkeley.edu<br />
                  (805) 555-0000
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  1200 Channing Drive<br />
                  Berkeley, CA
                </div>
              </section>
              <section>
                <div class="col-sm-12 text-center"><h5><strong>Education</strong></h5></div>
              </section>
              <section>
                <div class="col-sm-10">
                  <strong style="font-size: 1.2em;">University of California, Berkeley</strong><br />
                  First-year student studying Computer Science, GPA 4.0
                </div>
                <div class="col-sm-2 text-right">
                  <em>Berkeley, CA<br />
                  2013-Present</em>
                </div>
              </section>
              <br />
              <section>
                <div class="col-sm-12">
                  <strong>INDEPENDENCE HIGH SCHOOL</strong><br />
                  Magna cum Laude, Honor Roll, Electronics Academy Award, STRUT Computer Competition Bronze Medal, Robotics club, Greenhouse club, Kids for Community
                </div>
              </section>
              <section>
                <div class="col-sm-12 text-center"><h5><strong>Experience</strong></h5></div>
              </section>
              <section>
                <div class="col-sm-9">
                  <strong>Lunch - Math Peer Tutoring</strong><br />
                  <strong>Peer Tutor</strong><br />
                  Tutored high school freshmen in algebra
                </div>
                <div class="col-sm-3 text-right">
                  <em>Berkeley, CA<br />
                  Oct 2012-Nov 2012</em>
                </div>
              </section>
              <br />
              <section>
                <div class="col-sm-9">
                  <strong>Math Club</strong><br />
                  <strong>Vice President</strong><br />
                  Worked to organize mathe club events on campuss and attract more members
                </div>
                <div class="col-sm-3 text-right">
                  <em>Berkeley, CA<br />
                  Dec 2012-June 2013</em>
                </div>
              </section>
              <section>
                <div class="col-sm-12 text-center"><h5><strong>Skills & Interests</strong></h5></div>
              </section>
              <section>
                <div class="col-sm-12">
                  <strong>Computer:</strong> Microsoft PowerPoint<br />
                  <strong>Language:</strong> English, Vietnamese<br />
                  <strong>Interests:</strong> oral communications, classrom presentations, computer programming, social service
                </div>
              </section>
            </div>'
        },
        {
          label: "Eric's Résumé",
          content: '
             <div style="font-family: georgia; padding: 5em;">
              <section>
                <div class="col-sm-12">
                  Eric Smith<br />
                  2650 Haste Street Berkeley, CA 94720 | 415-999-0000
                  <hr style="border-color: #000;" />
                </div>
              </section>
              <section>
                <div class="col-sm-12 text-center"><h5><strong>Education</strong></h5></div>
              </section>
              <section>
                <div class="col-sm-6">
                  <strong>UNIVERSITY OF CALIFORNIA, BERKELEY</strong><br />
                  Intended major: business administration
                </div>
                <div class="col-sm-6 text-right">
                  Berkeley, CA<br />
                  Expected graduation date: May 2017
                </div>
              </section>
              <br />
              <section>
                <div class="col-sm-9">
                  <strong>PHILLIP AND SALA BURTON ACADEMIC HIGH SCHOOL</strong><br />
                  Graduated with high honors. GPA 3.9.
                </div>
                <div class="col-sm-3 text-right">
                  San Francisco, CA<br />
                  May 2013
                </div>
              </section>
              <section>
                <div class="col-sm-12 text-center"><h5><strong>Experiences and Leadership</strong></h5></div>
              </section>
              <section>
                <div class="col-sm-6">
                  <strong>HALL ASSOCIATION</strong><br />
                  <em>Secretary</em>
                </div>
                <div class="col-sm-6 text-right">
                  Berkeley, CA<br />
                  September 2013 - Present
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  <ul>
                    <li>Record and post minutes during meetings for residents to be up-to-date with future events and sign ups</li>
                    <li>Feedback was collected and organized in a committee I led to discuss residential concerns.</li>
                  </ul>
                </div>
              </section>
              <br />
              <section>
                <div class="col-sm-6">
                  <strong>YEARBOOK</strong><br />
                  <em>Executive Managing Editor</em>
                </div>
                <div class="col-sm-6 text-right">
                  San Francisco, CA<br />
                  August 2012 - May 2013
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  <ul>
                    <li>Monitored picture quality and consistency and ensured that spreads were completed on time</li>
                    <li>Edited spreads with precision and accuracy for the Final product</li>
                  </ul>
                </div>
              </section>
              <br />
              <section>
                <div class="col-sm-6">
                  <strong>OFFICE OF PRINCIPAL</strong><br />
                  <em>Assistant</em>
                </div>
                <div class="col-sm-6 text-right">
                  San Francisco, CA<br />
                  August 2013 - May 2013
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  <ul>
                    <li>Answered phone calls and recorded messages, constructed school fliers, assembled copies, reminded staff of meetings, inputted data, documented files, and outreached to peers</li>
                  </ul>
                </div>
              </section>
              <br />
              <section>
                <div class="col-sm-6">
                  <strong>ASSOCIATED STUDENT BODY</strong><br />
                  <em>Treasurer</em>
                </div>
                <div class="col-sm-6 text-right">
                  San Francisco, CA<br />
                  January 2012 - January 2013
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  <ul style="list-style-type: square;">
                    <li>Fund raised finances for the senior class and budgeted events and activities</li>
                    <li>Collected money and kept/updated orders/records for senior class hoodies and Events such as Food Fest, Senior Skate Night, and Senior Class Trip</li>
                  </ul>
                </div>
              </section>
              <br />
              <section>
                <div class="col-sm-6">
                  <strong>DAXIN GENERAL MERCHANDISE STORE</strong><br />
                  <em>Volunteer</em>
                </div>
                <div class="col-sm-6 text-right">
                  San Francisco, CA<br />
                  August 2009 - May 2011
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  <ul>
                    <li>Volunteered as an assistant to greet customers, record sales, restock and organize merchandise, answer phone calls, and translate administrative letters</li>
                  </ul>
                </div>
              </section>
              <section>
                <div class="col-sm-12 text-center"><h5><strong>Skills & Interests</strong></h5></div>
              </section>
              <section>
                <div class="col-sm-12">
                  <strong>Computer:</strong> Microsoft Word, Power Point, can type approximately 80 words per minute<br /><br />
                  <strong>Other:</strong> Very detail-oriented and organized, adequate skills in Mandarin<br /><br />
                  <strong>Interests:</strong> Marathon running, watching basketball and taking new cooking classes - Thai and Italian cuisine
                </div>
              </section>
            </div>'
        },
        {
          label: "Amanda's Résumé",
          content: '
            <div style="font-family: georgia; padding: 5em;">
              <section>
                <div class="col-sm-12 text-center">
                  <span style="font-size: 2.5em; font-weight: bold;">AMANDA SMITH</span><br />
                  2732 Channing Way, Berkeley, CA 94704 | Amanda_smith@berkeley.edu
                </div>
              </section>
              <section>
                <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;"><strong>EDUCATION</strong></h5></div>
              </section>
              <section>
                <div class="col-sm-6">
                  <strong>UNIVERSITY OF CALIFORNIA, BERKELEY</strong><br />
                  <ul style="list-style-type: square;">
                    <li>Intended Political Economy Major</li>
                  </ul>
                </div>
                <div class="col-sm-6 text-right">
                  <strong>Expected Graduation Date: May 2017</strong><br />
                  <strong>Cumulative GPA:</strong> 3.53
                </div>
              </section>
              <section>
                <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;"><strong>PROFESSIONAL EXPERIENCE</strong></h5></div>
              </section>
              <section>
                <div class="col-sm-9">
                  <strong>LYFT | ON-DEMAND RIDE SHARING</strong><br />
                  Campus Growth manager | January 2014 - Present
                </div>
                <div class="col-sm-3 text-right">
                  <strong><em>Berkeley, CA</em></strong>
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  <ul style="list-style-type: square;">
                    <li>Utilized social media, personal networking and partnering with UC Berkeley organizations in order to promote the download and usage of Lyft application</li>
                    <li>Developed and coordinated events with local Berkeley city businesses in order to expose Lyft to the East Bay Area</li>
                  </ul>
                </div>
              </section>
              <section>
                <div class="col-sm-9">
                  <strong>SPOTIFY | MRY MARKETING</strong><br />
                  Campus Influencer | January 2014 - Present
                </div>
                <div class="col-sm-3 text-right">
                  <strong><em>Berkeley, CA</em></strong>
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  <ul style="list-style-type: square;">
                    <li>Created social awareness of Spotify through traditional marketing and social media; distributing product materials through hosted events and in-person interactions with students on campus</li>
                  </ul>
                </div>
              </section>
              <section>
                <div class="col-sm-9">
                  <strong>WINDOWS 8 | FLUENT MARKETING</strong><br />
                  Promotional Representative | September 2013 - February 2014
                </div>
                <div class="col-sm-3 text-right">
                  <strong><em>Berkeley, CA</em></strong>
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  <ul style="list-style-type: square;">
                    <li>Formally trained in the features of Windows 8.1 in order to market the program and features to those in the Berkeley community</li>
                    <li>DWorked with multiple, extremely extroverted Brand Ambassadors; distributed promotional materials and registered booth visitors to Visa and Windows Tablet giveaways</li>
                    <li>Used social media and traditional forms of marketing techniques to promote the Windows 8 Tour on campus; managed response surveys to improve tour efficiency</li>
                  </ul>
                </div>
              </section>
              <section>
                <div class="col-sm-9">
                  <strong>HYUNDAI | INFIELD PROMO MARKETING</strong><br />
                  Promotional Representative | September 2013 – November 2014
                </div>
                <div class="col-sm-3 text-right">
                  <strong><em>Berkeley, CA</em></strong>
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  <ul style="list-style-type: square;">
                    <li>Collaborated with a team of five personable promotional models to showcase Hyundai\'s newest car models and to help market Hyundai to UC Berkeley alumni who are in the car market</li>
                    <li>Directed booth visitors to iPad kiosks to register for Hyundai’s national car giveaway</li>
                  </ul>
                </div>
              </section>
              <section>
                <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;"><strong>LEADERSHIP EXPERIENCE & ACTIVITIES</strong></h5></div>
              </section>
              <section>
                <div class="col-sm-12">
                  <strong>BEYOND Z ACADEMY</strong> | Beta Tester and Member of Inaugural Class (2014-Present)
                  <ul style="list-style-type: square;">
                    <li>Working with a team of eight students on leadership development projects that emphasized professional network and personal brand marketing; engaging with other participants from San Jose State, Stanford and San Francisco State</li>
                    <li>Beta tested the BZ leadership program and development of the academy for 10 weeks; utilizing results learned to benefit low-income college students in developing confidence and leadership abilities</li>
                  </ul>
                </div>
              </section>
              <section>
                <div class="col-sm-12">
                  <strong>GAMMA PHI BETA PANHELLENIC SORORITY</strong> | Assistant Membership Vice President
                  <ul style="list-style-type: square;">
                    <li>Coordinated with current Membership Vice President to plan and execute 2014 recruitments through to grow the number of members, who not only reflect the organization’s values, but could continue to grow the in leadership and development</li>
                    <li>Attended formal round tables with other MVP’s of other Panhellenic chapters to plan for recruiting over 800 potential sorority women</li>
                  </ul>
                </div>
              </section>
              <section>
                <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;"><strong>Skills & Interests</strong></h5></div>
              </section>
              <section>
                <div class="col-sm-12">
                  <strong>Languages:</strong> Fluent in Spanish| Proficient in Tagalog<br />
                  <strong>Technical Skills:</strong> Photoshop/Photo Editing, Google Analytics<br />
                  <strong>Workshop Experience:</strong> Interpersonal Connections/Communications, Improvisation, Leadership Development<br />
                  <strong>Interests:</strong> Singing, Drawing
                </div>
              </section>
            </div>'
        }
      ],
      answer: 2
    }.to_json
  )
)
item.task_definitions.push(task_definition)

task_definition = TaskDefinition.create(
  required: true, position: 5, name: 'Formatting',
  details: '<p>Your résumé in college should fill 1 page. Overall, Louis\'
    résumé is too short (only fills up a half page) and looks underwhelming
    because there is more white space than words. The header of the résumé does
    not stand out and there are also some grammar errors and typos.</p>

    <div class="html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12 text-center">
          <strong class="context-notes" data-placement="top"
            data-content="Font size should be at least 20+ to feature more
            prominently as header. Overall, this résumé is too short – it needs
            to fill 1 page">Louis Smith
          </strong><br />
          Louis17@sjsu.edu<br />
          (805) 555-7777
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <span class="context-notes" data-placement="top" data-content="This
            should be justified in the center.">
            3268 Andora Drive<br />
            San Jose, CA 95148
          </span>
        </div>
      </section>
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Education</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong class="context-notes" data-placement="top"
            data-content="Font size is larger here and the font looks different.
            Formatting should be consistent throughout to make it a professional
            résumé." style="font-size: 1.2em;">
            University of California, Berkeley
          </strong><br />
          First-year student studying Computer Science, GPA 4.0
        </div>
        <div class="col-sm-3 text-right">
          <em>Berkeley, CA<br />
          2013-Present</em>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-12">
          <strong>INDEPENDENCE HIGH SCHOOL</strong><br />
          <span class="context-notes" data-placement="top" data-content="Clear
            and easy to read formatting is crucial in a résumé. Under the
            headers, Louis should put his descriptors in bullets below.">
            Magna cum Laude, Honor Roll, Electronics Academy Award, STRUT
            Computer Competition Bronze Medal, Robotics club, Greenhouse club,
            Kids for Community
          </span>
        </div>
      </section>
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Experience</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong>Lunch - Math Peer Tutoring</strong><br />
          <strong>Peer Tutor</strong><br />
          Tutored high school freshmen in algebra
        </div>
        <div class="col-sm-3 text-right">
          <em>San Jose, CA<br />
          2013-Present</em>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-9">
          <strong>Math Club</strong><br />
          <strong>Vice President</strong><br />
          Worked to organize
          <span class="context-notes" data-placement="top"
            data-content="Spelling error">mathe</span>
          club events on
          <span class="context-notes" data-placement="top"
          data-content="Spelling errors – must catch these and proofread">
            campuss</span>
          and attract more members
        </div>
        <div class="col-sm-3 text-right">
          <em>San Jose, CA<br />
          2013-Present</em>
        </div>
      </section>
      <div class="context-notes" data-placement="top" data-content="The Leadership section is missing on this résumé. Louis is forgetting to put in leadership roles in clubs, involvement in extra-curricular activities, awards, and research">&nbsp;</div>
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Skills & Interests</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-12">
          <strong>Computer:</strong> Microsoft PowerPoint<br />
          <strong>Language:</strong>Vietnamese, Spanish<br />
          <strong>Interests:</strong> oral communications, classrom presentations, computer programming, social service
        </div>
      </section>
    </div>
    <br />
    <br />

    <p>Although Eric\'s résumé fills the 1 page, overall, this résumé
    is mediocre, bordering on poor quality. The name in the header does not
    stand out and an email address is missing. There are also spelling errors
    and some variation in bullet formatting and font sizes, which make it look
    inconsistent.</p>

    <div class="html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12">
          <span class="context-notes" data-placement="top" data-content="Name
            should be centered">Eric Smith</span><br />
          <span class="context-notes" data-placement="top" data-content="Eric
            is missing his school email address, which I  a big error – it does
            not make it easy for a potential employer to reach him for an
            interview.">2650 Haste Street Berkeley, CA 94720 | 415-999-0000</span>
          <hr style="border-color: #000;" />
        </div>
      </section>
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Education</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-6">
          <strong>UNIVERSITY OF CALIFORNIA, BERKELEY</strong><br />
          Intended major: business administration
        </div>
        <div class="col-sm-6 text-right">
          Berkeley, CA<br />
          Expected graduation date: May 2017
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-9">
          <strong>PHILLIP AND SALA BURTON ACADEMIC HIGH SCHOOL</strong><br />
          Graduated with high honors. GPA 3.9.
        </div>
        <div class="col-sm-3 text-right">
          San Francisco, CA<br />
          May 2013
        </div>
      </section>
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Experiences and Leadership</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-6">
          <strong>HALL ASSOCIATION</strong><br />
          <em>Secretary</em>
        </div>
        <div class="col-sm-6 text-right">
          Berkeley, CA<br />
          September 2013 - Present
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul>
            <li>Record and post minutes during meetings for residents to be up-to-date with future events and sign ups</li>
            <li>Feedback was collected and organized in a committee I led to discuss residential concerns.</li>
          </ul>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-6">
          <strong>YEARBOOK</strong><br />
          <em>Executive Managing Editor</em>
        </div>
        <div class="col-sm-6 text-right">
          San Francisco, CA<br />
          August 2012 - May 2013
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul>
            <li>Monitored picture quality and consistency and ensured that spreads were completed on time</li>
            <li>Edited spreads with precision and accuracy for the Final product</li>
          </ul>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-6">
          <strong>OFFICE OF PRINCIPAL</strong><br />
          <em>Assistant</em>
        </div>
        <div class="col-sm-6 text-right">
          San Francisco, CA<br />
          August 2013 - May 2013
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul>
            <li>Answered phone calls and recorded messages, constructed school fliers, assembled copies, reminded staff of meetings, inputted data, documented files, and outreached to peers</li>
          </ul>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-6">
          <strong>ASSOCIATED STUDENT BODY</strong><br />
          <em>Treasurer</em>
        </div>
        <div class="col-sm-6 text-right">
          San Francisco, CA<br />
          January 2012 - January 2013
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul style="list-style-type: square;" class="context-notes" data-placement="top" data-content="Bullets are different here and should be consistently formatted with other bullets for a professional look">
            <li>Fund raised finances for the senior class and budgeted events and activities</li>
            <li>Collected money and kept/updated orders/records for senior class hoodies and Events such as Food Fest, Senior Skate Night, and Senior Class Trip</li>
          </ul>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-6">
          <strong>DAXIN GENERAL MERCHANDISE STORE</strong><br />
          <em>Volunteer</em>
        </div>
        <div class="col-sm-6 text-right">
          San Francisco, CA<br />
          August 2009 - May 2011
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul>
            <li>Volunteered as an assistant to greet customers, record sales, restock and organize merchandise, answer phone calls, and translate administrative letters</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Skills & Interests</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-12">
          <strong>Computer:</strong> Microsoft Word, Power Point, can type approximately 80 words per minute<br /><br />
          <strong>Other:</strong> Very detail-oriented and organized, adequate skills in Mandarin<br /><br />
          <strong>Interests:</strong> Marathon running, watching basketball and taking new cooking classes - Thai and Italian cuisine
        </div>
      </section>
    </div>
    <br />
    <br />

    <p>Overall, this résumé is formatted well. It fills the 1 page but is
    not overcrowded. There are no grammatical or spelling errors. The name on
    the header at the top is bold and stands out in a larger size font,
    attracting attention. This résumé could be improved – Amanda left out her
    phone number, which is important for contacting purposes.</p>

    <div class="html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12 text-center">
          <span style="font-size: 2.5em; font-weight: bold;">AMANDA SMITH</span><br />
          <span class="context-notes" data-placement="top" data-content="Kimberly\'s résumé is missing a phone number. A simple but very crucial mistake to avoid – you want to make it as easy for an employer to reach out to you in case they are interested in inviting you for an interview.">2732 Channing Way, Berkeley, CA 94704 | Amanda_smith@berkeley.edu</span>
        </div>
      </section>
      <section>
        <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;" class="context-notes" data-placement="top" data-content="While this résumé is well formatted, Amanda can improve her résumé by increasing the font size of the headers or bolding them to differentiate the different sections of her résumé. As it stands, the sections (Education, Experience, Leadership, Skills and Experiences) blend in together too much."><strong>EDUCATION</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-6">
          <strong>UNIVERSITY OF CALIFORNIA, BERKELEY</strong><br />
          <ul style="list-style-type: square;">
            <li>Intended Political Economy Major</li>
          </ul>
        </div>
        <div class="col-sm-6 text-right">
          <strong>Expected Graduation Date: May 2017</strong><br />
          <strong>Cumulative GPA:</strong> 3.53
        </div>
      </section>
      <section>
        <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;" class="context-notes" data-placement="top" data-content="Amanda should differentiate the header here from the experiences listed below. As it reads, they blend on together."><strong>PROFESSIONAL EXPERIENCE</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong>LYFT | ON-DEMAND RIDE SHARING</strong><br />
          Campus Growth manager | January 2014 - Present
        </div>
        <div class="col-sm-3 text-right">
          <strong><em>Berkeley, CA</em></strong>
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul style="list-style-type: square;">
            <li>Utilized social media, personal networking and partnering with UC Berkeley organizations in order to promote the download and usage of Lyft application</li>
            <li>Developed and coordinated events with local Berkeley city businesses in order to expose Lyft to the East Bay Area</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong>SPOTIFY | MRY MARKETING</strong><br />
          Campus Influencer | January 2014 - Present
        </div>
        <div class="col-sm-3 text-right">
          <strong><em>Berkeley, CA</em></strong>
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul style="list-style-type: square;">
            <li>Created social awareness of Spotify through traditional marketing and social media; distributing product materials through hosted events and in-person interactions with students on campus</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong>WINDOWS 8 | FLUENT MARKETING</strong><br />
          Promotional Representative | September 2013 - February 2014
        </div>
        <div class="col-sm-3 text-right">
          <strong><em>Berkeley, CA</em></strong>
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul style="list-style-type: square;">
            <li>Formally trained in the features of Windows 8.1 in order to market the program and features to those in the Berkeley community</li>
            <li>DWorked with multiple, extremely extroverted Brand Ambassadors; distributed promotional materials and registered booth visitors to Visa and Windows Tablet giveaways</li>
            <li>Used social media and traditional forms of marketing techniques to promote the Windows 8 Tour on campus; managed response surveys to improve tour efficiency</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong>HYUNDAI | INFIELD PROMO MARKETING</strong><br />
          Promotional Representative | September 2013 – November 2014
        </div>
        <div class="col-sm-3 text-right">
          <strong><em>Berkeley, CA</em></strong>
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul style="list-style-type: square;">
            <li>Collaborated with a team of five personable promotional models to showcase Hyundai\'s newest car models and to help market Hyundai to UC Berkeley alumni who are in the car market</li>
            <li>Directed booth visitors to iPad kiosks to register for Hyundai’s national car giveaway</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;"><strong>LEADERSHIP EXPERIENCE & ACTIVITIES</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-12">
          <strong>BEYOND Z ACADEMY</strong> | Beta Tester and Member of Inaugural Class (2014-Present)
          <ul style="list-style-type: square;">
            <li>Working with a team of eight students on leadership development projects that emphasized professional network and personal brand marketing; engaging with other participants from San Jose State, Stanford and San Francisco State</li>
            <li>Beta tested the BZ leadership program and development of the academy for 10 weeks; utilizing results learned to benefit low-income college students in developing confidence and leadership abilities</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <strong>GAMMA PHI BETA PANHELLENIC SORORITY</strong> | Assistant Membership Vice President
          <ul style="list-style-type: square;">
            <li>Coordinated with current Membership Vice President to plan and execute 2014 recruitments through to grow the number of members, who not only reflect the organization’s values, but could continue to grow the in leadership and development</li>
            <li>Attended formal round tables with other MVP’s of other Panhellenic chapters to plan for recruiting over 800 potential sorority women</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;"><strong>Skills & Interests</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-12">
          <strong>Languages:</strong> Fluent in Spanish| Proficient in Tagalog<br />
          <strong>Technical Skills:</strong> Photoshop/Photo Editing, Google Analytics<br />
          <strong>Workshop Experience:</strong> Interpersonal Connections/Communications, Improvisation, Leadership Development<br />
          <strong>Interests:</strong> Singing, Drawing
        </div>
      </section>
    </div>'
  )

item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 6, name: 'Education section',
  details: '<p>This résumé does a fairly good job to state the basics and
    includes: university name, location, major and even shows off an impressive
    GPA – 4.0! If you have a strong GPA (3.0 or higher) include that on your
    résumé.  Louis could improve this résumé by adding in relevant college
    classes taken or academic honors he has received at school and his expected
    graduation date. Louis also includes his high school experience and does a
    good job to cite the honors he has received. However, his high school
    section could be more organized, clear and well defined in bullets, as
    opposed to a list.</p>
    <br />
    <div class="partial-html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Education</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong style="font-size: 1.2em;">
            University of California, Berkeley
          </strong><br />
          First-year student studying Computer Science, GPA 4.0
        </div>
        <div class="col-sm-3 text-right">
          <em>Berkeley, CA<br />
          2013-Present</em>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-12">
          <strong>INDEPENDENCE HIGH SCHOOL</strong><br />
          <span class="context-notes" data-placement="top" data-content="If
            Louis has a strong high school GPA (3.5 or higher) – he should
            include it here and type into his résumé. Right after honor roll
            and state 3.6 GPA for example.">
            Magna cum Laude, Honor Roll, Electronics Academy Award, STRUT
            Computer Competition Bronze Medal, Robotics club, Greenhouse club,
            Kids for Community
          </span>
        </div>
      </section>
    </div>
    <br />
    <br />


    <p>Eric\'s education section is also strong. He includes
    the university, location, intended major and includes his expected
    graduation date. Eric also includes his high school experience, and while
    he does a good job to list his strong GPA, he could have also included
    honors and accomplishments he achieved in high school in this section (i.e.
    won a nationally recognized award in athletics, or academics or started a
    company/founded a nonprofit organization in high school). One note: Eric
    is a business administration major, and if he is applying for a consulting
    orfinance internship, some employers in those fields might be interested in
    his math SAT scores and math or technical SAT II scores, which he could
    include in this section if they are strong.</p>
    <br />
    <div class="partial-html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Education</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-6">
          <strong>UNIVERSITY OF CALIFORNIA, BERKELEY</strong><br />
          <span class="context-notes" data-placement="top" data-content="Eric could include relevant classes or coursework taken that relate to the  internship/scholarship/program he is applying to.">
            Intended major: business administration
          </span>
        </div>
        <div class="col-sm-6 text-right">
          Berkeley, CA<br />
          Expected graduation date: May 2017
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-9">
          <strong>PHILLIP AND SALA BURTON ACADEMIC HIGH SCHOOL</strong><br />
          <span class="context-notes" data-placement="top" data-content="Also
            include any honor societies or high school honors received.">
            Graduated with high honors. GPA 3.9.
          </span>
        </div>
        <div class="col-sm-3 text-right">
          San Francisco, CA<br />
          May 2013
        </div>
      </section>
    </div>
    <br />
    <br />

    <p>Amanda\'s education section is strong. She includes the university,
    her major, and lists her strong GPA and expected graduation date. While
    this is a solid section, there are ways Amanda could improve this section:
    she could add in relevant coursework from her intended major and she also
    leaves off her high school experience, which she could keep on, if she has
    some extraordinary accomplishments.</p>
    <br />
    <div class="partial-html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;"><strong>EDUCATION</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-6">
          <strong>UNIVERSITY OF CALIFORNIA, BERKELEY</strong><br />
          <ul style="list-style-type: square;">
            <li class="context-notes" data-placement="top" data-content="Amanda could include relevant coursework and classes that she’s taking if it relates to an internship she is applying for.">Intended Political Economy Major</li>
          </ul>
        </div>
        <div class="col-sm-6 text-right">
          <strong>Expected Graduation Date: May 2017</strong><br />
          <strong>Cumulative GPA:</strong> 3.53
        </div>
      </section>
    </div>
    <br />
    <br />
    '
  )

item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 7, name: 'Experience section',
  details: '<p>The experience section is the most important section on a
    résumé and showcases your potential for accomplishment. Louis’ descriptions
    are not detailed and don’t illustrate the experience with concrete examples.
    He also needs to write about more experiences – at least 3-4 experiences would
    flesh this section out and give a more complete picture of Louis.</p>
    <br />
    <div class="partial-html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Experience</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong>Lunch - Math Peer Tutoring</strong><br />
          <strong>Peer Tutor</strong><br />
          <span class="context-notes" data-placement="top"
            data-content="Louis needs to list at least 3 more experiences, and
            include more details that describe what each of these experiences is.
            He also should consider using more action verbs to strengthen his
            experiences. Some examples, \'Organized week-long community service
            program for 10-12 incoming freshmen\' \'Attended and drafted summaries
            of relevant congressional hearings.\'
            Louis can improve this statement by including the # of high school
            freshmen he tutored so that it’s more specific.">
            Tutored high school freshmen in algebra
          </span>
        </div>
        <div class="col-sm-3 text-right">
          <em>San Jose, CA<br />
          2013-Present</em>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-9">
          <strong>Math Club</strong><br />
          <strong>Vice President</strong><br />
          Worked to organize mathe club events on campuss and attract more members
        </div>
        <div class="col-sm-3 text-right">
          <em>San Jose, CA<br />
          2013-Present</em>
        </div>
      </section>
    </div>
    <br />
    <br />

    Eric’s experience section does an OK job to list out bulleted
    descriptions. However, Eric does 2 things that stand in the way of
    super-charging his résumé. First, he uses passive voice (i.e., " Feedback was
    collected and organized in a Committee I lead") versus active action verbs
    "Organized and coordinated a feedback process" that give his résumé a
    stronger, leadership stance. Second, he doesn\'t include enough specific and
    concrete details/numbers in his descriptions of his résumé. For example, he
    could include the number of residents he helped to organize to strengthen the
    impact of this section.</p>
    <br />
    <div class="partial-html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Experiences and Leadership</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-6">
          <strong>HALL ASSOCIATION</strong><br />
          <em>Secretary</em>
        </div>
        <div class="col-sm-6 text-right">
          Berkeley, CA<br />
          September 2013 - Present
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul>
            <li>Record and post minutes during meetings for residents to be up-to-date with future events and sign ups</li>
            <li class="context-notes" data-placement="top" data-content="Eric
              can use stronger action verbs to convey more of his accomplishments
              and avoid passive voice. When asked more about his experiences and
              leadership he could rewrite to say, \'Lead feedback collection
              process of over 50 residents on housing amenities for committee
              discussions on housing improvements.\' Eric can also include number
              of residents he organized.">Feedback was collected and organized in
              a committee I led to discuss residential concerns.</li>
          </ul>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-6">
          <strong>YEARBOOK</strong><br />
          <em>Executive Managing Editor</em>
        </div>
        <div class="col-sm-6 text-right">
          San Francisco, CA<br />
          August 2012 - May 2013
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul>
            <li><span class="context-notes" data-placement="top"
              data-content="Suggested stronger action words: Oversaw,  Managed,
              etc.">Monitored</span> picture quality and consistency and ensured
              that spreads were completed on time</li>
            <li>Edited spreads with precision and accuracy for the Final product</li>
          </ul>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-6">
          <strong>OFFICE OF PRINCIPAL</strong><br />
          <em>Assistant</em>
        </div>
        <div class="col-sm-6 text-right">
          San Francisco, CA<br />
          August 2013 - May 2013
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul>
            <li>Answered phone calls and recorded messages, constructed school fliers, assembled copies, reminded staff of meetings, inputted data, documented files, and outreached to peers</li>
          </ul>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-6">
          <strong>ASSOCIATED STUDENT BODY</strong><br />
          <em>Treasurer</em>
        </div>
        <div class="col-sm-6 text-right">
          San Francisco, CA<br />
          January 2012 - January 2013
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul style="list-style-type: square;">
            <li>Fund raised finances for the senior
              class and budgeted events and activities</li>
            <li><span class="context-notes" data-placement="top"
              data-content="Suggested stronger action words: Organized,
              Administered, etc.">Collected</span> money and kept/updated
              orders/records for senior class hoodies and Events such as Food
              Fest, Senior Skate Night, and Senior Class Trip</li>
          </ul>
        </div>
      </section>
      <br />
      <section>
        <div class="col-sm-6">
          <strong>DAXIN GENERAL MERCHANDISE STORE</strong><br />
          <em>Volunteer</em>
        </div>
        <div class="col-sm-6 text-right">
          San Francisco, CA<br />
          August 2009 - May 2011
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul>
            <li>Volunteered as an assistant to greet customers, record sales, restock and organize merchandise, answer phone calls, and translate administrative letters</li>
          </ul>
        </div>
      </section>
    </div>
    <br />
    <br />

    <p>Amanda\'s experience section is solid. Her accomplishment statements
    lead with strong action verbs and she included specific and concrete details
    that elaborate on her achievements and the impact she has. She could improve
    her résumé by including more numbers as details for her achievements. For
    instance, she writes, "Developed and coordinated events with local Berkeley
    City businesses" and she could strengthen this instead with "Developed and
    coordinated 10 outreach events with 3 local Berkeley businesses to highlight
    the use of solar power and energy conservation."</p>
    <br />
    <div class="partial-html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;"><strong>PROFESSIONAL EXPERIENCE</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong>LYFT | ON-DEMAND RIDE SHARING</strong><br />
          Campus Growth manager | January 2014 - Present
        </div>
        <div class="col-sm-3 text-right">
          <strong><em>Berkeley, CA</em></strong>
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul style="list-style-type: square;">
            <li>Utilized social media, personal networking and partnering with UC Berkeley organizations in order to promote the download and usage of Lyft application</li>
            <li>Developed and coordinated events with local Berkeley city businesses in order to expose Lyft to the East Bay Area</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong>SPOTIFY | MRY MARKETING</strong><br />
          Campus Influencer | January 2014 - Present
        </div>
        <div class="col-sm-3 text-right">
          <strong><em>Berkeley, CA</em></strong>
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul style="list-style-type: square;">
            <li>Created social awareness of Spotify through traditional marketing and social media; distributing product materials through hosted events and in-person interactions with students on campus</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong>WINDOWS 8 | FLUENT MARKETING</strong><br />
          Promotional Representative | September 2013 - February 2014
        </div>
        <div class="col-sm-3 text-right">
          <strong><em>Berkeley, CA</em></strong>
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul style="list-style-type: square;">
            <li>Formally trained in the features of Windows 8.1 in order to market the program and features to those in the Berkeley community</li>
            <li>DWorked with multiple, extremely extroverted Brand Ambassadors; distributed promotional materials and registered booth visitors to Visa and Windows Tablet giveaways</li>
            <li>Used social media and traditional forms of marketing techniques to promote the Windows 8 Tour on campus; managed response surveys to improve tour efficiency</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-9">
          <strong>HYUNDAI | INFIELD PROMO MARKETING</strong><br />
          Promotional Representative | September 2013 – November 2014
        </div>
        <div class="col-sm-3 text-right">
          <strong><em>Berkeley, CA</em></strong>
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <ul style="list-style-type: square;">
            <li>Collaborated with a team of five personable promotional models to showcase Hyundai\'s newest car models and to help market Hyundai to UC Berkeley alumni who are in the car market</li>
            <li>Directed booth visitors to iPad kiosks to register for Hyundai’s national car giveaway</li>
          </ul>
        </div>
      </section>
    </div>
    <br />
    <br />
    '
  )

item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 8, name: 'Leadership section',
  details: '<p>The leadership section in Louis\' résumé is missing. He is
    not taking advantage of an opportunity through his résumé to showcase
    critical experiences and skills that might give him an edge in securing an
    internship or job interview.</p>

    <p>Eric\'s leadership section is merged together with his
    experience section, which is OK, because he clearly states the leadership
    titles, positions, and dates he has held these positions in the different
    organizations he has worked with.</p>

    <p>Amanda\'s leadership section clearly lists leadership skills and
    dates of involvement, although she could select stronger action verbs to
    describe these skills. In addition, one of her action verbs is in a
    different tense – "Working" when it should read "Worked" to maintain
    consistency with the rest of her action verbs in the past tense. She does a
    good job to include specific numbers and details that flesh out her
    accomplishments.</p>
    <br />
    <div class="partial-html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;"><strong>LEADERSHIP EXPERIENCE & ACTIVITIES</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-12">
          <strong>BEYOND Z ACADEMY</strong> | Beta Tester and Member of Inaugural Class (2014-Present)
          <ul style="list-style-type: square;">
            <li><span class="context-notes" data-placement="top" data-content="The tense of the action verbs for all sections should be the same. Amanda uses past tense for all sections except for this, where she uses present tense – she should change this sentence to read, \'Worked with a team of eight cohorts….\'">Working</span> with a team of eight students on leadership development projects that emphasized professional network and personal brand marketing; engaging with other participants from San Jose State, Stanford and San Francisco State</li>
            <li>Beta tested the BZ leadership program and development of the academy for 10 weeks; utilizing results learned to benefit low-income college students in developing confidence and leadership abilities</li>
          </ul>
        </div>
      </section>
      <section>
        <div class="col-sm-12">
          <strong>GAMMA PHI BETA PANHELLENIC SORORITY</strong> | Assistant Membership Vice President
          <ul style="list-style-type: square;">
            <li>Coordinated with current Membership Vice President to plan and execute 2014 recruitments through to grow the number of members, who not only reflect the organization’s values, but could continue to grow the in leadership and development</li>
            <li>Attended formal round tables with other MVP’s of other Panhellenic chapters to plan for recruiting over 800 potential sorority women</li>
          </ul>
        </div>
      </section>
    </div>
    <br />
    <br />
    '
  )

item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 9, name: 'Skills and experiences',
  details: '<p>This section is weak. Louis includes some skills but is not
    clear. For example, he lists languages, but does not provide level of
    fluency – i.e.: conversational Vietnamese and fluent Spanish. He also lists
    out his interests, but could include more specific examples of the social
    service and computer programming activities he engages in order to make the
    reviewer have a more complete picture of the type of well-rounded person
    Louis is outside of his studies and extra-curricular activities.</p>
    <br />
    <div class="partial-html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Skills & Interests</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-12">
          <strong>Computer:</strong> Microsoft PowerPoint<br />
          <strong>Language:</strong> <span class="context-notes" data-placement="top"
            data-content="Include level of fluency – Conversational, or
            fluent">Vietnamese, Spanish</span><br />
          <strong>Interests:</strong> oral communications, classrom presentations,
          computer programming, social service
        </div>
      </section>
    </div>
    <br />
    <br />

    <p>Eric\'s skills and interest section is listed clearly with
    bulleted details provided. His listed interests flesh out his activities
    outside of school and showcase his athletic and culinary pursuits that don\'t
    necessarily come through any other section until the end of the résumé. He
    could improve this section by relabeling "Other" to "Languages Spoken" and
    removing the sentence "very detailed-oriented and organized" which is too
    generic to fit into this section, which is really about highlighting unique
    skills and interests.</p>
    <br />
    <div class="partial-html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12 text-center"><h5><strong>Skills & Interests</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-12">
          <strong>Computer:</strong> <span class="context-notes"
            data-placement="top" data-content="Eric could add in any social
            media skills to Computer skills section which will strengthen this.">
            Microsoft Word, Power Point, can type approximately 80 words per minute
            </span><br /><br />
          <strong>Other:</strong> Very detail-oriented and organized, <span class="context-notes"
            data-placement="top" data-content="Reword – proficient, fluent, or
            conversational in Mandarin">adequate skills in</span> Mandarin<br /><br />
          <strong>Interests:</strong> <span class="context-notes"
            data-placement="top" data-content="Eric could include more details on
            community involvement or volunteering that will round out his
            profile more.">Marathon running, watching basketball and taking new
            cooking classes - Thai and Italian cuisine</span>
        </div>
      </section>
    </div>
    <br />
    <br />

    <p>Amanda\'s skills and interest section clearly lists her skills
    with some details to flesh out her interests.  Since this section is meant
    to showcase unique skills and interests, so she could also include even
    more details that provide more flavor to her specific interests – including
    number of years she has done improve theater, or the type of leadership
    development conferences she has attended.</p>
    <br />
    <div class="partial-html-document" style="font-family: georgia; padding: 5em;">
      <section>
        <div class="col-sm-12"><h5 style="padding-bottom: 1px; border-bottom: solid 1px #000;"><strong>Skills & Interests</strong></h5></div>
      </section>
      <section>
        <div class="col-sm-12">
          <strong>Languages:</strong> Fluent in Spanish| Proficient in Tagalog<br />
          <strong>Technical Skills:</strong> Photoshop/Photo Editing, Google Analytics<br />
          <strong>Workshop Experience:</strong> Interpersonal Connections/Communications, Improvisation, Leadership Development<br />
          <strong>Interests:</strong> Singing, Drawing
        </div>
      </section>
    </div>
    <br />
    <br />
    '
  )

item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 10, requires_approval: true,
  name: "Compose your Résumé",
  summary: 'A solid résumé is key to getting into the door of the job you want.',
  details: '<h3>Write your résumé - 3 steps</h3>
      <h4>1) Brainstorm</h4>
      <p>
        Before writing your résumé, take some time to brainstorm your key
        accomplishments using the following worksheet.
      </p>
      <p>
        <a href="/docs/resume_brainstorming.docx">Résumé brainstorming worksheet (Word)</a>
      </p>
      <p>
        Jot down the first answers that come to mind and don\'t worry about
        them being exact or perfect. Take a look at the brainstorm questions
        below to get you started: 
      </p>
      <ul>
        <li>What 3-5 accomplishments and professional skills do you want to
          make sure your internship supervisor/job employer sees on your
          résumé? What roles have you held that have allowed you to develop
          these skills?</li>
        <li>If there was 1 message that you want to convey to an employer
          through your résumé, what’s the point you want to make?</li>
      </ul>

      <h4>2) Next, research the internship, job or opportunity</h4>
      <ul>
        <li>
          Research the internship. Go to the company\'s website and see what
          language they use to describe the ideal candidates. Do a Google
          search for the company. Make sure your resume address each of the
          things they are asking for on their website.</li>
      </ul>

      <h4>3) Write a first draft of your résumé</h4>
      <ul>
        <li>Write out accomplishment statements. Makesure your statements are
          positive and proud, but don\'t overstate to the pointof falsely
          representing yourself or being untrue to your actual experience.</li>
        <li>Scan the Action Verb list to phrase your achievements so that you
          are the hero of your own resume.
          <p><a target="_BLANK" href="/docs/action-verbs.html">list of action verbs</a>.
          </p></li>
        <li>Jump-start the writing process by entering your accomplishments into
          the résumé template here.
          <p>
            <a href="/docs/resume_template.docx">Résumé template (Word)</a>
          </p>
        </li>
      </ul>
  '
  
)
# task_definition.sections.push(
#   TaskSection.create(
#     task_module_id: resume_builder_module.id,
#     introduction: 'Use the form below to complete your résumé.'
#   )
# )
item.task_definitions.push(task_definition)

task_definition = TaskDefinition.create(
  required: true, position: 11,
  requires_approval: true, name: 'Résumé',
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: file_upload_module.id,
    file_type: 'document',
    introduction: 'Please upload your new résumé once you have it finished. Your
     coach will provide feedback to you.'
  )
)
item.task_definitions.push(task_definition)
item.save

item = AssignmentDefinition.new
item.front_page_info = "
    <h3>You will get practice this week:</h3>
    <ul>
      <li><strong>Networks:</strong> Identify the members of participant networks who provide key supports.</li>
      <li><strong>Networks/ Self -Discipline: </strong> Learn habits and strategies that help to build a network.</li>
    </ul>
  "
item.title = "Week 3: Power through Networks"
item.led_by = "Coach"
item.assignment_download_url = "assignments/networks/submissions/new"
item.start_date = Time.parse("Mar 17")
item.end_date = Time.parse("Mar 23")
item.seo_name = "networks"
item.save
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1,
    name: 'Read the articles'
  )
)
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 2, requires_approval: true,
    name: 'Set-up LinkedIn Account and send to 10 connections.'
  )
)

task_definition = TaskDefinition.create(
  required: true, position: 3,
  requires_approval: true, name: 'Evidence of Applied Learning',
  details: 'Complete and upload <a href="https://www.dropbox.com/s/3n193wtct2tso3c/I%20%20Week%203_%20Power%20through%20Networks_EAL.docx?dl=1">Evidence of Applied Learning (EAL) </a> by 9 PM Friday, April 4th.'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: file_upload_module.id,
    file_type: 'document'
  )
)
item.task_definitions.push(task_definition)
item.save

item = AssignmentDefinition.new
item.front_page_info = "
          <h3>You will get practice this week:</h3>
          <ul>
            <li>Learning more about our strengths.</li>
            <li>Learning what others see in us and value about our contributions.</li>
            <li>Seeing our successes in new and different ways.</li> 
          </ul>
        "
item.title = 'Week 4: Spring Break!'
item.led_by = 'Peer'
item.assignment_download_url = 'assignments/best-self/submissions/new'
item.start_date = Time.parse("Mar 24")
item.end_date = Time.parse("Mar 30")
item.seo_name = "best-self"
item.save
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1,
    name: 'Best Self Exercise',
    details: 'Read the <a href="https://www.dropbox.com/s/9jb9zvt1lpdcovv/K%20%20Week%204_Spring%20Break%20-%20Best%20Self%20Exercise%20Request.docx?dl=1">Best Self Exercise</a>.'
  )
)

task_definition = TaskDefinition.create(
  required: true, position: 2,
  requires_approval: true, name: 'Evidence of Applied Learning',
  details: 'Complete and upload <a href="https://www.dropbox.com/s/ucddx42at97b9iv/K%20%20Week%204_Spring%20Break%20-%20Best%20Self%20Exercise%20Request_EAL.docx?dl=1">Evidence of Applied Learning (EAL)</a> by 9 PM, Friday, April 4th.'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: file_upload_module.id,
    file_type: 'document'
  )
)
item.task_definitions.push(task_definition)
item.save

item = AssignmentDefinition.new
item.front_page_info = "
          <h3>You will get practice this week:</h3>
          <ul>
            <li><strong>Agency:</strong> Explain what it means to have a growth mindset vs. a fixed mindset.</li>
            <li><strong>Agency:</strong> Determine what challenges college participants are facing in college and how they can work to overcome them (the challenges they face may or may not be associated with growth mindset).</li>
            <li><strong>Agency:</strong> Prepare to talk about challenges in an interview.</li>
            <li><strong>Personal Assets:</strong> Create a personal empowerment statement that supports going Beyond Z</li>
            <li><strong>Self-Discipline:</strong> Learn to successfully cope with disappointment and discuss what changes have you made in how you approach challenges or deal with disappointment.</li>
          </ul>
        "
item.title = 'Week 5: Failing & Asking for Help'
item.led_by = 'Coach'
item.assignment_download_url = 'assignments/asking-for-help/submissions/new'
item.start_date = Time.parse("Mar 31")
item.end_date = Time.parse("Apr 6")
item.seo_name = "asking-for-help"
item.save
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1, name: 'Write Blog #1',
    summary: 'Topic: Give guidance to younger BZ students about overcoming hardship.'
  )
)
item.task_definitions.push(
    TaskDefinition.create(
      required: true, position: 2, requires_approval: true,
      name: 'Contacts for the Best Self Exercise (by Friday, April 4th)',
      details: 'Give your coach 2 contacts for the <a href="https://www.dropbox.com/s/9jb9zvt1lpdcovv/K%20%20Week%204_Spring%20Break%20-%20Best%20Self%20Exercise%20Request.docx?dl=1">Best Self Exercise</a> by Friday, April 4th.'
    )
  )
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 3, requires_approval: true,
    name: 'Sign up for mock interviews',
    details: 'Sign up for mock interviews <a href="https://docs.google.com/spreadsheet/ccc?key=0AqSVLa-AGkW_dEIzT2t0NG9iRWY5XzBqbWVqZ0tqb0E&amp;usp=sharing">here</a>.'
  )
)

task_definition = TaskDefinition.create(
  required: true, position: 4,
  requires_approval: true, name: 'Evidence of Applied Learning',
  details: 'Complete and upload <a href="https://www.dropbox.com/s/4mjwhueiaje18wy/L%20%20Week%205_Failing%20and%20Learning%20-%20EAL.docx?dl=1">Evidence of Applied Learning (EAL)</a> by 9 PM, Friday, April 11th.'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: file_upload_module.id,
    file_type: 'document'
  )
)
item.task_definitions.push(task_definition)
item.save

item = AssignmentDefinition.new
item.front_page_info = "
          <h3>You will get practice this week:</h3>
          <ul>
            <li>Knowing the basics of interviewing (overview information, types of interviews, etc.)</li>
            <li>Researching the industry and organization</li>
            <li>Preparing key questions and practicing strategies to respond to typical interview question and ace them! This includes: strategies of telling your personal story without making it sound like a pity story and determining when it&#8217;s appropriate to talk about one&#8217;s background or challenges they&#8217;ve had to overcome.</li>
            <li>Communicating your skills, interest, and &quot;fit&quot; with the org.</li>
            <li>Remembering the key details (dress, etiquette, going to the interview site in advance, etc.)</li>
            <li>Following up after an interview with a thank you email or card.</li>
          </ul>
        "
item.title = 'Week 6: Perfecting Your Interviewing Skills'
item.led_by = 'Peer'
item.assignment_download_url = 'assignments/interview-simulations/submissions/new'
item.start_date = Time.parse("Apr 7")
item.end_date = Time.parse("13")
item.seo_name = "interview-simulations"
item.save
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1,
    name: 'Go through Steps 1-6',
    details: 'Optional Resources to check out: Interview Simulator and Online Flashcards.'
  )
)
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 2, requires_approval: true,
    name: 'Interview Sign-up',
    summary: 'Sign-up for 1 phone interview and 1 in-person mock interview',
    details: 'Sign-up by Sunday, April 6 here: <a href="https://docs.google.com/spreadsheet/ccc?key=0AqSVLa-AGkW_dEIzT2t0NG9iRWY5XzBqbWVqZ0tqb0E&amp;usp=sharing">Mock Interview Sign-Up Form</a>:  (Sign up for a total of 2 mock interviews)'
  )
)

task_definition = TaskDefinition.create(
  required: true, position: 3, requires_approval: true,
  name: 'Evidence of Applied Learning',
  details: 'Complete and upload <a href="https://www.dropbox.com/s/p4du6bcv1ypbtxj/N%20%20Week%206_Career%20Portfolio_Interviews_EAL.docx?dl=1">Evidence of Applied Learning (EAL)</a> by 9 PM Friday, April 11th.'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: file_upload_module.id,
    file_type: 'document'
  )
)
item.task_definitions.push(task_definition)
item.save

item = AssignmentDefinition.new
item.front_page_info = "
          <h3>Theme: Intersections</h3>
          <p>We are looking to convene all Beyond Z Fellows for a Midpoint Summit on Saturday, April 12 in San Francisco. Fellows will receive an opportunity to synthesize lessons and reflections thus far in the Academy, while practicing their skills in networking and interviewing.</p>
          <p>
          The theme of this Summit is &#8220;Intersections.&#8221; BZ Fellows will explore where their leadership identities, their cultural heritage (7 generations), and their academic and summer aspirations intersect and connect.  They will also explore their own development and who they are now and how it intersects with their visions for themselves in the future. This theme is also reinforced by the community leaders who attend the Summit as part of leadership and career panels, who will draw focus on to the intersections of interests, career passions, and ways of giving back to the world that they share with BZ students. Furthermore, a focus on &#8220;story of us&#8221; and &#8220;story of now&#8221; will draw more community connections among BZ students across different university campuses and what they can to together as a community of leaders.
          </p>
        "
item.title = "BZ Academy Midpoint Summit:"
item.start_date = Time.parse("Apr 12")
item.seo_name = "dropbox.com/s/gaycnymb36ji6c9/BZ%20Academy%20Midpoint%20Summit%20Agenda.docx?dl=1"
item.save
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1,
    name: 'Copies of your résumé and cover letter',
    details: 'Make 10 copies of your résumé and cover letter for distribution.'
  )
)
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 2,
    name: 'Your padfolio (from weekend 0) and pen'
  )
)
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 3,
    name: 'Your A-Game for interviewing and networking practice!'
  )
)
item.save

item = AssignmentDefinition.new
item.front_page_info = "
          <h3>You will get practice this week:</h3>
          <ul>
            <li><strong>Agency:</strong> To learn skills to overcome a low work ethic and to identify best practices to help someone build a stronger worth ethic?</li>
            <li><strong>Seven Generations:</strong> Identify role models that have a strong worth ethic and commitment, drive, and hunger to succeed.  Understand how they have benefited from previous generations that have been driven to provide a better life for future generations and how they plan to pay it forward.</li>
            <li><strong>Self-Discipline:</strong> To reflect on their own work ethic and generate insights.</li>
            <li><strong>Goal Setting:</strong> To develop an action plan and to have pods work together in support.</li>
          </ul>
        "
item.title = "Week 7: Work Ethic"
item.led_by = "Coach"
item.assignment_download_url = "assignments/work-ethic/submissions/new"
item.start_date = Time.parse("Apr 14")
item.end_date = Time.parse("Apr 20")
item.seo_name = "work-ethic"
item.save
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1,
    name: 'Read "30 Under 30 Leaders who are changing the world!"',
    details: 'For inspiration read <a href="http://www.forbes.com/special-report/2014/30-under-30/finance.html">30 Under 30 Leaders who are changing the world!</a>'
  )
)
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 2, requires_approval: true,
    name: 'Write Blog #2',
    summary: 'Topic: What keeps you driven to succeed and how you stay organized and on track to meet that goal.'
  )
)

task_definition = TaskDefinition.create(
  required: true, position: 3, requires_approval: true,
  name: 'This Document',
  details: 'Complete and upload <a href="#?dl=1">this document</a> by 9 PM Friday, April 25th.'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: file_upload_module.id,
    file_type: 'document'
  )
)
item.task_definitions.push(task_definition)
item.save

item = AssignmentDefinition.new
item.front_page_info = "
          <h3>You will get practice this week:</h3>
          <ul>
            <li>Using 2 tools. Big Rocks, &#8220;To-Do&#8221; lists to improve effectiveness and exchange ideas on other old school and technologically enhanced organization methods across the pod.</li>
            <li>Learning about other online tools and apps to stay on top of your priorities and life.</li>
            <li>Discuss strategies to enter</li>
          </ul>
        "
item.title = "Week 8: Organization & Self-Management"
item.led_by = "Peer"
item.assignment_download_url = "assignments/organization-self-mgmt/submissions/new"
item.start_date = Time.parse("Apr 21")
item.end_date = Time.parse("Apr 27")
item.seo_name = "organization-self-mgmt"
item.save
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1, requires_approval: true,
    name: 'Write Blog #3'
  )
)
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 2, requires_approval: true,
    name: 'Write job search advice',
    summary: 'Write advice on staying organized and on top of your summer opportunity search.'
  )
)

task_definition = TaskDefinition.create(
  required: true, position: 3,
  requires_approval: true, name: 'This Document',
  details: 'Complete and upload <a href="#?dl=1">this document</a> by 9 PM Friday, May 2nd.'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: file_upload_module.id,
    file_type: 'document'
  )
)
item.task_definitions.push(task_definition)
item.save

User.all.each { |u| u.create_child_skeleton_rows }
