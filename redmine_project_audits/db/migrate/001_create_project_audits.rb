class CreateProjectAudits < ActiveRecord::Migration[7.2]
  def change
    create_table :project_audits do |t|
      # Usamos integer para ser compatibles con la BD nativa de Redmine 7
      t.references :user, type: :integer, null: false, foreign_key: true, index: true
      t.integer :project_id, index: true # Sin foreign key estricta para no perder el log si el proyecto se borra
      t.string :project_name, null: false
      t.string :action_type, null: false # 'create', 'update', 'destroy'
      
      t.datetime :created_at, null: false
    end
  end
end
