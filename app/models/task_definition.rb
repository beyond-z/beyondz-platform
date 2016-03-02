# A task is made out of a name, summary, details, and sections.
#
# * The name is a text title that's displayed to the user.
# * The summary is a brief text paragraph that explains what it is.
#
# Note that the name and summary may be displayed on an assignment list overview
# or other navigation aid.
#
# * The details is a HTML area that details the task or includes multimedia
#   content, such as video and image tags. These tags may also include relevant
#   data such as video start times, links, or quiz metadata. The details should
#   be an overview of the task - information the user needs to get started,
#   such as directions to the student.
#
# * The sections are groupings of related data that includes additional pieces
#   called modules which have questions or other interactive content or may have
#   additional html based content to present to the user. This is the meat of
#   the embedded task. There may be zero or more sections and each section may
#   consist of several related modules (for example, a resume to look at, then
#   some questions to critique it it may be several modules in a single section.)
#   A task with zero sections ought to give the user everything they need in the
#   details, for example, a link to an outside website.
class TaskDefinition < ActiveRecord::Base
  belongs_to :assignment_definition
  has_many :tasks, dependent: :destroy
  has_many :sections, class_name: 'TaskSection', dependent: :destroy

  default_scope { order('position ASC') }
  scope :required, -> { where(required: true) }
  scope :not_required, -> { where(required: false) }
  scope :require_approval, -> { where(requires_approval: true) }
  scope :do_not_require_approval, -> { where(requires_approval: false) }
end
