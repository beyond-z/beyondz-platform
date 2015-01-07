ad = AssignmentDefinition.find_by_seo_name('resume')
tasks = TaskDefinition.where('assignment_definition_id' => ad.id)
intro = TaskDefinition.find(12)

intro.details = "<p>Your resum&eacute; is the crown jewel of your career portfolio. Just\n      like companies have logos and \"brand reputations\" where they are publicly\n 
nown for certain things, a resum&eacute; reflects your own personal brand and\n      represents what you stand for as a leader and as a professional. It's one\n 
f the most important professional documents that represents you.</p>\n      
<p>We’re going to meet Louis, Eric, and Amanda. They are all sophomore\n      students at UC Berkeley and are competing for the same summer internship\n      in education in DC over the summer and have all created their resum&eacute;s.\n      Based on their resum&eacute;s, we're going to have you predict which one has the\n      best shot and scoring an interview.</p>\n      \n      <object width=\"560\" height=\"315\">\n        <param name=\"movie\" value=\"/videos/Interactive_Resume_Louis_Amanda_Eric_Intro_Video.swf\" />\n        <embed src=\"/videos/Interactive_Resume_Louis_Amanda_Eric_Intro_Video.swf\" width=\"560\" height=\"315\"></embed>\n      </object>\n      "

intro.save!

page2 = TaskDefinition.find(13)

page2.details = "<p>But before you rank resumes, we go to unpack the basic\n      building blocks of a resume and discuss what makes a good resume.</p>\n\n      <object width=\"600\" height=\"337\">\n        <param name=\"movie\" value=\"/videos/Interactive_Resume_Parts_Video.swf\" />\n        <embed src=\"/videos/Interactive_Resume_Parts_Video.swf\" width=\"600\" height=\"337\"></embed>\n      </object>\n 
	<p><a href=\"/docs/Joe Anonymous Resume.docx\">Download the example resume here.</a></p>
"             
page2.save!


page3 = TaskSection.find(8)
page3.configuration = page3.configuration.sub("Louis17@sjsu.edu", "Louis.Smith17@gmail.com")
page3.configuration = page3.configuration.sub("DWorked", "Worked")
page3.save!

page4 = TaskDefinition.find(16)
page4.details = page4.details.sub("Louis17@berkeley.edu", "Louis.Smith17@gmail.com")
page4.details = page4.details.sub("DWorked", "Worked")
page4.save!

page8 = TaskDefinition.find(19)

page8.details = "<p>The leadership section in Louis' resume is missing. He is\n    not taking advantage of an opportunity through his resume to showcase\n    critical experiences and skills that might give him an edge in securing an\n    internship or job interview.</p>\n\n    <p>Eric's leadership section is merged together with his\n    experience section, which is OK, because he clearly states the leadership\n    titles, positions, and dates he has held these positions in the different\n    organizations he has worked with.</p>\n\n  


<div class=\"partial-html-document\" style=\"font-family: georgia; padding: 5em;\"> <section>\n                <div class=\"col-sm-12 text-center\"><h5><strong>Experiences and Leadership</strong></h5></div>\n              </section>\n              <section>\n                <div class=\"col-sm-6\">\n                  <strong>HALL ASSOCIATION</strong><br />\n                  <em>Secretary</em>\n                </div>\n                <div class=\"col-sm-6 text-right\">\n                  Berkeley, CA<br />\n                  September 2013 - Present\n                </div>\n              </section>\n              <section>\n                <div class=\"col-sm-12\">\n                  <ul>\n li>Record and post minutes during meetings for residents to be up-to-date with future events and sign ups</li>\n                    <li>Feedback was collected and organized in a committee I led to discuss residential concerns.</li>\n                  </ul>\n                </div>\n              </section>\n              <br />\n              <section>\n <div class=\"col-sm-6\">\n                  <strong>YEARBOOK</strong><br />\n                  <em>Executive Managing Editor</em>\n                </div>\n                <div class=\"col-sm-6 text-right\">\n                  San Francisco, CA<br />\n                  August 2012 - May 2013\n                </div>\n              </section>\n <section>\n                <div class=\"col-sm-12\">\n                  <ul>\n                    <li>Monitored picture quality and consistency and ensured that spreads were completed on time</li>\n                    <li>Edited spreads with precision and accuracy for the Final product</li>\n                  </ul>\n                </div>\n              </section>\n              <br />\n              <section>\n                <div class=\"col-sm-6\">\n                  <strong>OFFICE OF PRINCIPAL</strong><br />\n                  <em>Assistant</em>\n                </div>\n                <div class=\"col-sm-6 text-right\">\n                  San Francisco, CA<br />\n                  August 2013 - May 2013\n </div>\n              </section>\n              <section>\n                <div class=\"col-sm-12\">\n                  <ul>\n                    <li>Answered phone calls and recorded messages, constructed school fliers, assembled copies, reminded staff of meetings, inputted data, documented files, and outreached to peers</li>\n                  </ul>\n </div>\n              </section>\n              <br />\n              <section>\n                <div class=\"col-sm-6\">\n                  <strong>ASSOCIATED STUDENT BODY</strong><br />\n                  <em>Treasurer</em>\n                </div>\n                <div class=\"col-sm-6 text-right\">\n                  San Francisco, CA<br />\n January 2012 - January 2013\n                </div>\n              </section>\n              <section>\n                <div class=\"col-sm-12\">\n                  <ul style=\"list-style-type: square;\"><li>Fund raised finances for the senior class and budgeted events and activities</li>\n                    <li>Collected money and kept/updated orders/records for senior class hoodies and Events such as Food Fest, Senior Skate Night, and Senior Class Trip</li>\n                  </ul>\n                </div>\n              </section>\n              <br />\n              <section>\n                <div class=\"col-sm-6\">\n                  <strong>DAXIN GENERAL MERCHANDISE STORE</strong><br />\n                  <em>Volunteer</em>\n                </div>\n                <div class=\"col-sm-6 text-right\">\n                  San Francisco, CA<br />\n August 2009 - May 2011\n                </div>\n              </section>\n              <section>\n                <div class=\"col-sm-12\">\n                  <ul>\n <li>Volunteered as an assistant to greet customers, record sales, restock and organize merchandise, answer phone calls, and translate administrative letters</li>\n </ul>\n                </div>\n              </section>\n  </div>

<p>Amanda's leadership section clearly lists leadership skills and\n    dates of involvement, although she could select stronger action verbs to\n    describe these skills. In addition, one of her action verbs is in a\n    different tense – \"Working\" when it should read \"Worked\" to maintain\n    consistency with the rest of her action verbs in the past tense. She does a\n    good job to include specific numbers and details that flesh out her\n    accomplishments.</p>\n    <br />\n    <div class=\"partial-html-document\" style=\"font-family: georgia; padding: 5em;\">\n      <section>\n        <div class=\"col-sm-12\"><h5 style=\"padding-bottom: 1px; border-bottom: solid 1px #000;\"><strong>LEADERSHIP EXPERIENCE & ACTIVITIES</strong></h5></div>\n      </section>\n      <section>\n        <div class=\"col-sm-12\">\n          <strong>BEYOND Z ACADEMY</strong> | Beta Tester and Member of Inaugural Class (2014-Present)\n          <ul style=\"list-style-type: square;\">\n            <li><span class=\"context-notes\" data-placement=\"top\" data-content=\"The tense of the action verbs for all sections should be the same. Amanda uses past tense for all sections except for this, where she uses present tense – she should change this sentence to read, 'Worked with a team of eight cohorts….'\">Working</span> with a team of eight students on leadership development projects that emphasized professional network and personal brand marketing; engaging with other participants from San Jose State, Stanford and San 
rancisco State</li>\n            <li>Beta tested the BZ leadership program and development of the academy for 10 weeks; utilizing results learned to benefit 
ow-income college students in developing confidence and leadership abilities</li>\n          </ul>\n        </div>\n      </section>\n      <section>\n 
 <div class=\"col-sm-12\">\n          <strong>GAMMA PHI BETA PANHELLENIC SORORITY</strong> | Assistant Membership Vice President\n          <ul style=\"list-style-type: square;\">\n            <li>Coordinated with current Membership Vice President to plan and execute 2014 recruitments through to grow the number of members, who not only reflect the organization’s values, but could continue to grow the in leadership and development</li>\n            <li>Attended formal round tables with other MVP’s of other Panhellenic chapters to plan for recruiting over 800 potential sorority women</li>\n          </ul>\n        </div>\n 
  </section>\n    </div>\n    <br />\n    <br />\n    "

page8.save!





