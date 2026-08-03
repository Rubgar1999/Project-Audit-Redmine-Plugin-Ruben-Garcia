module RedmineProjectAudits
  module ProjectPatch
    extend ActiveSupport::Concern

    included do
      after_create :audit_project_creation
      after_update :audit_project_update
      before_destroy :audit_project_destruction
    end

    private

    def audit_project_creation
      record_project_audit('crear')
    end

    def audit_project_update
      # Solo registra 'editar' si realmente hubo cambios en el proyecto
      record_project_audit('editar') if self.saved_changes?
    end

    def audit_project_destruction
      record_project_audit('borrar')
    end

    def record_project_audit(action)
      # Validamos estrictamente que haya un usuario logueado en ese momento
      return unless User.current && User.current.logged?
      
      ProjectAudit.create!(
        user_id: User.current.id,
        project_id: self.id,
        project_name: self.name,
        action_type: action,
        created_at: Time.current
      )
    rescue => e
      # Si hay un error, lo envía al log de Redmine en lugar de romper la página
      Rails.logger.error "+++ ERROR PLUGIN AUDITORIA PROYECTOS: #{e.message} +++"
    end
  end
end
