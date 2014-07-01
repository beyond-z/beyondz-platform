# This file should contain all the record creation needed to seed the database
# with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db
# with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

user = User.new(email: "test+student1@beyondz.org", password: "test", first_name: "BeyondZ", last_name: "Test")
user2 = User.new(email: "test+student2@beyondz.org", password: "test", first_name: "Second", last_name: "Student")
coach = User.new(email: "test+coach1@beyondz.org", password: "test", first_name: "BeyondZ", last_name: "Coach")
admin_user = User.new(email: "test+admin@beyondz.org", password: "test", first_name: "BeyondZ", last_name: "Admin", is_administrator: true)

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
resume_builder_module = TaskModule.create(name: 'Resumé Builder', code: 'resume_builder')
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
item.title = "Weekend 0 Launch: The Story of Self and Us"
item.led_by = "Staff"
item.assignment_download_url = "https://docs.google.com/a/beyondz.org/forms/d/1cgwwrGn3ZMNkrKvL-Uj4FNz1Qf27xPc6usqse7fTWBg/viewform"
item.start_date = Time.parse("Feb 28")
item.end_date = Time.parse("Mar 1")
item.seo_name = "story-of-self"
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
            <li><strong>NOTE: This is a 2-part module that asks you to write a Resume and a Cover Letter, spending a total of 3 hours across both assignments.</strong></li>
          </ul>
        "
item.title = "Week 2(a): Cover Letter"
item.led_by = "Peer"
item.assignment_download_url = "assignments/cover-letter/submissions/new"
item.start_date = Time.parse("Mar 10")
item.end_date = Time.parse("Mar 16")
item.seo_name = "cover-letter"
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
      <li>Emphasizing your assets as you write your resume.</li>
      <li>Practice giving feedback on another college participant&#8217;s resume.</li>
      <li>Finding summer internships and tailoring your resume to different opportunities that you identify.</li>
      <li><strong>NOTE: This is a 2-part module that asks you to write a Resume and a Cover Letter, spending a total of 3 hours across both artifacts.</strong></li>
    </ul>
  "
item.title = "Week 2(b): Resume"
item.led_by = "Peer"
item.assignment_download_url = "assignments/resume/submissions/new"
item.start_date = Time.parse("Mar 10")
item.end_date = Time.parse("Mar 16")
item.seo_name = "resume"
item.save
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 1,
    name: 'Your resumé',
    details: '<p>Your resumé is the crown jewel of your career portfolio. Just
      like companies have logos and "brand reputations" where they are publicly
      known for certain things, a resumé reflects your own personal brand and
      represents what you stand for as a leader and as a professional. It\'s one
      of the most important professional documents that represents you.</p>
      <p>A good resumé will help you to open doors to interviews for competitive
      internships and job opportunities. Your objective in crafting a resumé is
      to set yourself apart from hundreds or thousands of other candidates and
      position yourself as a unique candidate.</p>
      <p>We’re going to meet Alex, Eric, and Amanda. They are all sophomore
      students at UC Berkeley and are competing for the same summer internship
      in education in DC over the summer and have all created their resumés.
      Based on their resumés, we\'re going to have you predict which one has the
      best shot and scoring an interview.</p>'
  )
)
item.task_definitions.push(
  TaskDefinition.create(
    required: true, position: 2,
    name: 'Parts of a resumé',
    details: '<p>But before you rank resumes, we go to unpack the basic
      building blocks of a resume and discuss what makes a good resume.</p>
      <iframe width="560" height="315" src="//www.youtube.com/embed/PAthQKLhBTs?rel=0" frameborder="0" allowfullscreen></iframe>'
  )
)
task_definition = TaskDefinition.create(
  required: true, position: 3, name: 'Formatting',
  summary: 'Determine which resumés have the best formatting.',
  details: '<p>This is an entire paragraph about what makes good resumé
    formatting. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
    non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>'
  )
task_definition.sections.push(
  TaskSection.create(
    task_module_id: compare_module.id,
    introduction: 'Review each resume and rate their formatting below.',
    configuration: {
      item_label: 'Resumé',
      items: [
        {
          label: 'Resumé 1',
          content: '
            <div>
              <h3>John Doe</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div>
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div>
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div>
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 2',
          content: '
            <div>
              <h3>John Dough</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div>
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div>
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div>
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 3',
          content: '
            <div>
              <h3>John DOH</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div>
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div>
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div>
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        }
      ],
      answer: 2
    }.to_json
  )
)
item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 4, name: 'Education section',
  summary: 'Determine which resumés have the best education section.',
  details: '<p>This is an entire paragraph about what makes a good education section.
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
    non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>'
  )
task_definition.sections.push(
  TaskSection.create(
    task_module_id: compare_module.id,
    introduction: 'Review each resume and rate their educaion section below.',
    configuration: {
      item_label: 'Resumé',
      items: [
        {
          label: 'Resumé 1',
          content: '
            <div class="lowlight">
              <h3>John Doe</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div class="lowlight">
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div class="highlight">
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 2',
          content: '
            <div class="lowlight">
              <h3>John Dough</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div class="lowlight">
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div class="highlight">
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 3',
          content: '
            <div class="lowlight">
              <h3>John DOH</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div class="lowlight">
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div class="highlight">
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        }
      ],
      answer: 2
    }.to_json
  )
)
item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 5, name: 'Experience section',
  summary: 'Determine which resumés have the best experience section.',
  details: '<p>This is an entire paragraph about what makes a good experience section.
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
    non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>'
  )
task_definition.sections.push(
  TaskSection.create(
    task_module_id: compare_module.id,
    introduction: 'Review each resume and rate their experience section below.',
    configuration: {
      item_label: 'Resumé',
      items: [
        {
          label: 'Resumé 1',
          content: '
            <div class="lowlight">
              <h3>John Doe</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div class="lowlight">
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div class="highlight">
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 2',
          content: '
            <div class="lowlight">
              <h3>John Dough</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div class="lowlight">
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div class="highlight">
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 3',
          content: '
            <div class="lowlight">
              <h3>John DOH</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div class="lowlight">
             <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div class="highlight">
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        }
      ],
      answer: 2
    }.to_json
  )
)
item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 6, name: 'Leadership section',
  summary: 'Determine which resumés have the best leadership section.',
  details: '<p>This is an entire paragraph about what makes a good leadership section.
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
    non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>'
  )
task_definition.sections.push(
  TaskSection.create(
    task_module_id: compare_module.id,
    introduction: 'Review each resume and rate their leadership section below.',
    configuration: {
      item_label: 'Resumé',
      items: [
        {
          label: 'Resumé 1',
          content: '
            <div>
              <h3>John Doe</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div>
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div>
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div>
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 2',
          content: '
            <div>
              <h3>John Dough</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div>
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div>
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div>
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 3',
          content: '
            <div>
              <h3>John DOH</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div>
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div>
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div>
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        }
      ],
      answer: 2
    }.to_json
  )
)
item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 7, name: 'Skills and experiences',
  summary: 'Determine which resumés have the best skills and experiences section.',
  details: '<p>This is an entire paragraph about what makes a good skills and experience section.
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
    non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>'
  )
task_definition.sections.push(
  TaskSection.create(
    task_module_id: compare_module.id,
    introduction: 'Review each resume and rate their skills and experience section below.',
    configuration: {
      item_label: 'Resumé',
      items: [
        {
          label: 'Resumé 1',
          content: '
            <div class="lowlight">
              <h3>John Doe</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div class="highlight">
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 2',
          content: '
            <div class="lowlight">
              <h3>John Dough</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div class="highlight">
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 3',
          content: '
            <div class="lowlight">
              <h3>John DOH</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div class="highlight">
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div class="lowlight">
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        }
      ],
      answer: 2
    }.to_json
  )
)
item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 8, name: 'Rank the resumés',
  summary: 'Determine which resumés are the strongest and weakest.',
  details: '<p>This is an entire paragraph about what makes a good resumé.
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
    non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>'
  )
task_definition.sections.push(
  TaskSection.create(
    task_module_id: compare_module.id,
    introduction: 'Review each resume and rate them below.',
    configuration: {
      item_label: 'Resumé',
      items: [
        {
          label: 'Resumé 1',
          content: '
            <div>
              <h3>John Doe</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div>
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div>
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div>
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 2',
          content: '
            <div>
              <h3>John Dough</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div>
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div>
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div>
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        },
        {
          label: 'Resumé 3',
          content: '
            <div>
              <h3>John DOH</h3>
              <p class="lead">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div>
              <h4>SKILLS</h4>
              <ul>
                <li>Nemo enim ipsam</li>
                <li>Incidunt ut labore</li>
                <li>Dolore magnam</li>
                <li>Aliquam quaerat voluptatem</li>
                <li>Voluptate velit esse quam</li>
              </ul>
            </div>
            <div>
              <h4>EXPERIENCE</h4>
              <ul>
                <li><h5>2013 - Present: Dolorem</h5>Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur.</li>
                <li><h5>2010 - 2013: Dignissimos</h5>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.</li>
                <li><h5>2008 - 2010: Neque</h5>Et harum quidem rerum facilis est et expedita distinctio.</li>
                <li><h5>2007 - 2008: Quis autem</h5>Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus.</li>
                <li><h5>2000 - 2007: Temporibus</h5>Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus.</li>
              </ul>
            </div>
            <div>
              <h4>EDUCATION</h4>
              <p>Masters in Photography from PU, 1981</p>
            </div>'
        }
      ],
      answer: 2
    }.to_json
  )
)
item.task_definitions.push(task_definition)
task_definition = TaskDefinition.create(
  required: true, position: 9, requires_approval: true,
  name: "Compose your Resumé",
  summary: 'A solid resume is key to getting into the door of the job you want.',
  details: '<p>This is an entire paragraph about how to make a good resumé.
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
    non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>'
)
task_definition.sections.push(
  TaskSection.create(
    task_module_id: resume_builder_module.id,
    introduction: 'Use the form below to complete your resumé.'
  )
)
item.task_definitions.push(task_definition)

task_definition = TaskDefinition.create(
  required: true, position: 10,
  requires_approval: true, name: 'Resumé',
  details: 'Submit resumé and complete Evidence of Applied Learning (EAL) by 9 PM Friday, March 21st.'
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
item.title = "Week 4: Spring Break!"
item.led_by = "Peer"
item.assignment_download_url = "assignments/best-self/submissions/new"
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
item.title = "Week 5: Failing & Asking for Help"
item.led_by = "Coach"
item.assignment_download_url = "assignments/asking-for-help/submissions/new"
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
item.title = "Week 6: Perfecting Your Interviewing Skills"
item.led_by = "Peer"
item.assignment_download_url = "assignments/interview-simulations/submissions/new"
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
    name: 'Copies of your resume and cover letter',
    details: 'Make 10 copies of your resume and cover letter for distribution.'
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

User.all.each do |u| u.create_child_skeleton_rows ; end
