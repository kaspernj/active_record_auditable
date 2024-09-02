class ActiveRecordAuditable::CreateAuditsTableForModelClass < ActiveRecordAuditable::ApplicationService
  arguments :model_class
  argument :create_table_args, default: nil
  argument :extra_table_actions, default: nil
  argument :id_type, default: nil

  def perform
    create_args = create_table_args || {}

    type_args = {}
    type_args[:type] = id_type if id_type

    ActiveRecord::Migration.new.create_table table_name, **create_args do |t|
      t.references model_class.model_name.param_key.to_sym, null: false, **type_args
      t.json :audited_changes
      t.references :audit_action, foreign_key: true, null: false, **type_args
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
