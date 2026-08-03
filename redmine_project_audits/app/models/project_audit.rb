class ProjectAudit < ActiveRecord::Base
  belongs_to :user
  # No ponemos 'belongs_to :project' porque si borran el proyecto,
  # queremos conservar el registro del nombre y el ID huérfano.
end
