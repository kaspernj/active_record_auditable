class ActiveRecordAuditable::TableData < ActiveRecordAuditable::ApplicationService
  arguments :model_class

  def perform
    dedicated_table_exists = dedicated_table_exists?

    if dedicated_table_exists
      inverse_of = model_class.model_name.param_key.to_sym
      foreign_key = "#{inverse_of}_id"

      succeed!(
        dedicated_table_exists:,
        dedicated_table_name:,
        foreign_key:,
        table_name: dedicated_table_name,
        audit_class: dedicated_audit_class,
        audit_class_name: "#{model_class.name}::Audit",
        inverse_of:,
        as: inverse_of
      )
    else
      succeed!(
        dedicated_table_exists:,
        dedicated_table_name:,
        foreign_key: "auditable_id",
        table_name: "audits",
        audit_class: ActiveRecordAuditable::Audit,
        audit_class_name: "ActiveRecordAuditable::Audit",
        inverse_of: :auditable,
        as: :auditable
      )
    end
  end

  def dedicated_audit_class
    if model_class.const_defined?("Audit")
      model_class.const_get("Audit")
    else
      base = model_class
      table_name = dedicated_table_name

      audit_class = Class.new(ActiveRecordAuditable::BaseAudit)
      audit_class.class_eval do
        self.table_name = table_name

        belongs_to base.model_name.param_key.to_sym, optional: true
        belongs_to :auditable, class_name: base.name, foreign_key: :"#{base.model_name.param_key}_id", optional: true

        def self.base_model
          reflections["auditable"].klass
        end

        def auditable_type
          self.class.reflections["auditable"].class_name
        end
      end

      model_class.const_set("Audit", audit_class)

      ActiveRecordAuditable::AuditAction.has_many(audit_class.model_name.plural.to_sym, class_name: audit_class.name)
      ActiveRecordAuditable::AuditAuditableType.has_many(audit_class.model_name.plural.to_sym, class_name: audit_class.name)

      audit_class
    end
  end

  def dedicated_table_name
    @dedicated_table_name ||= "#{model_class.table_name.singularize}_audits"
  end

  def dedicated_table_exists?
    ActiveRecordAuditable::Audited.__cached_audit_table_names.key?(dedicated_table_name)
  rescue ActiveRecord::StatementInvalid
    false
  end
end
