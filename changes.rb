aid = AssignmentDefinition.where(:seo_name => 'resume').first.id

# Fix up language: Alex should be Louis
td = TaskDefinition.where(:assignment_definition_id => aid, :position => 1).first

td.details.sub!('Alex', 'Louis')
td.save!

# Add instructions to page
td = TaskDefinition.where(:assignment_definition_id => aid, :position => 5).first
td.details = '<p>Instructions: Check out resumes for Louis, Amanda and Eric and take a close look at what they do well and where they could improve. You can hover over each of the (i) icons in gray to get a more detailed explanation on what they did and suggested tips and recommendations for improving your own resume.</p>' + td.details

# Fix up mistake: sjsu with berkeley 
td.details.sub!('sjsu', 'berkeley')

td.save!


# Delete the write your resume tasks as they are now in canvas
TaskDefinition.where(:assignment_definition_id => aid, :position => 10).first.destroy!
TaskDefinition.where(:assignment_definition_id => aid, :position => 11).first.destroy!

