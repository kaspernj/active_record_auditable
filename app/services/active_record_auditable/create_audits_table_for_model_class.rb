class ActiveRecordAuditable::CreateAuditsTableForModelClass < ActiveRecordAuditable::ApplicationService
  arguments :model_class
  argument :create_table_args
  argument :extra_table_actions, default: nil
  argument :id_type, default: nil
  argument :polymorphic_user_relation, default: true

  def perform
    create_args = create_table_args || {}

    ActiveRecord::Migration.new.create_table table_name, **create_args do |t|
      t.references :auditable, polymorphic: true, type: id_type

      if polymorphic_user_relation
        t.references :user, polymorphic: true, type: id_type
      else
        t.references :user, type: id_type
      end

      t.json :audited_changes
      t.references :audit_action, foreign_key: true, null: false, type: id_type
      t.references :audit_auditable_type, foreign_key: true, null: false, type: id_type
      t.json :params
      extra_table_actions.call(t) if extra_table_actions
      t.timestamps
    end

    succeed!
  end

  def table_name
    @table_name ||= "#{model_class.table_name.singularize}_audits"
  end
end
