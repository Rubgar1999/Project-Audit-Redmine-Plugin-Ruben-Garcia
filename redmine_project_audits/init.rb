Redmine::Plugin.register :redmine_project_audits do
  name 'Auditoría de Proyectos'
  author 'Ruben Garcia'
  description 'Plugin a medida para registrar la creación, modificación y borrado de proyectos.'
  version '1.0.0'
  requires_redmine version_or_higher: '7.0.0'
end

# Inyección directa al cargar el plugin (compatible con Producción y Rails 7.2)
Project.class_eval do
  unless method_defined?(:audit_project_creation)
    
    # Agregamos la nueva función espía antes de que se guarde el proyecto
    after_create :audit_project_creation
    before_update :capture_custom_fields_before_save
    after_update :audit_project_update
    before_destroy :audit_project_destruction

    def capture_custom_fields_before_save
      @cf_changes_for_audit = {}
      begin
        # 1. Buscamos el proyecto en la Base de Datos tal cual estaba ANTES de modificarse
        old_project = Project.find(self.id)
        
        # 2. Iteramos sobre los campos personalizados viejos
        old_project.custom_field_values.each do |cfv|
          # Formateamos el valor antiguo (maneja listas de múltiples opciones también)
          old_val = cfv.value.is_a?(Array) ? cfv.value.reject(&:blank?).join(', ') : cfv.value.to_s
          
          # 3. Buscamos el mismo campo en los nuevos datos que el usuario acaba de enviar
          new_cfv = self.custom_field_values.find { |v| v.custom_field_id == cfv.custom_field_id }
          if new_cfv
            new_val = new_cfv.value.is_a?(Array) ? new_cfv.value.reject(&:blank?).join(', ') : new_cfv.value.to_s
            
            # 4. Si el valor cambió, lo guardamos en la memoria temporal
            if old_val != new_val
              @cf_changes_for_audit["CF: #{cfv.custom_field.name}"] = [old_val, new_val]
            end
          end
        end
      rescue => e
        Rails.logger.error "+++ ERROR AUDITORIA CUSTOM FIELDS: #{e.message}"
      end
    end

    def audit_project_creation
      record_project_audit('crear')
    end

    def audit_project_update
      ignored_fields = %w[updated_on updated_at created_on created_at lft rgt id]
      
      # 1. Capturamos los cambios nativos de la tabla projects
      changes = saved_changes.except(*ignored_fields)
      
      # 2. FUSIONAMOS los cambios de Custom Fields que capturamos un paso antes
      if @cf_changes_for_audit.is_a?(Hash)
        changes.merge!(@cf_changes_for_audit)
      end

      # Si hubo cualquier tipo de cambio (nativo o personalizado), guardamos.
      if changes.any?
        record_project_audit('editar', changes.to_json)
      end
    end

    def audit_project_destruction
      record_project_audit('borrar')
    end

    def record_project_audit(action, details = nil)
      current_user_id = (User.current && User.current.id) || 1

      ProjectAudit.create!(
        user_id: current_user_id,
        project_id: self.id,
        project_name: self.name,
        action_type: action,
        details: details,
        created_at: Time.now.in_time_zone('America/Asuncion')
      )
    rescue => e
      Rails.logger.error "+++ ERROR PLUGIN AUDITORIA PROYECTOS: #{e.message}"
    end

  end
end
