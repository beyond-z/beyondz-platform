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
