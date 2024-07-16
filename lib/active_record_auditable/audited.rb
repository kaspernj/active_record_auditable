module ActiveRecordAuditable::Audited
  def self.included(base)
    base.has_one :create_audit, # rubocop:disable Rails/HasManyOrHasOneDependent
      -> { joins(:audit_action).where(audit_actions: {action: "create"}) },
      as: :auditable,
      class_name: "ActiveRecordAuditable::Audit",
      inverse_of: :auditable
    base.has_many :audits, # rubocop:disable Rails/HasManyOrHasOneDependent
      as: :auditable,
      class_name: "ActiveRecordAuditable::Audit",
      inverse_of: :auditable

    base.after_create do
      create_audit!(action: :create)
    end

    base.after_update do
      create_audit!(action: :update)
    end

    base.after_destroy do
      create_audit!(action: :destroy, audited_changes: attributes)
    end

    base.scope :without_audit, lambda { |action|
      audit_query = ActiveRecordAuditable::Audit
        .select(1)
        .joins(:audit_action)
        .where(auditable_type: base.model_name.name, audit_actions: {action:})
        .where("#{ActiveRecordAuditable::Audit.table_name}.auditable_id = #{base.table_name}.#{base.primary_key}")
        .limit(1)

      where("NOT EXISTS (#{audit_query.to_sql})")
    }
  end

  def create_audit!(action:, audited_changes: saved_changes_for_audit, **args)
    audit_data = {
      audit_action: find_or_create_auditable_action(action),
      audit_auditable_type_id: find_or_create_auditable_type.id,
      audited_changes:,
      auditable_id: id,
      auditable_type: self.model_name.name,
    }

    ActiveRecordAuditable::Audit.create!(audit_data.merge(args))
  end

  def audit_monitor
    @@audit_monitor ||= Monitor.new # rubocop:disable Style/ClassVars
  end

  def find_or_create_auditable_action(action)
    audit_monitor.synchronize do
      return ActiveRecordAuditable::AuditAction.find_or_create_by!(action:)
    end
  end

  def find_or_create_auditable_type
    audit_monitor.synchronize do
      return ActiveRecordAuditable::AuditAuditableType.find_or_create_by!(name: self.class.name)
    end
  end

  def saved_changes_for_audit
    saved_changes_for_audit = {}
    saved_changes.each do |attribute_name, from_and_to|
      saved_changes_for_audit[attribute_name] = from_and_to[1]
    end
    saved_changes_for_audit
  end
end
