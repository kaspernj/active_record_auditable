module ActiveRecordAuditable::Audited
  def self.included(base)
    base.has_one :create_audit, # rubocop:disable Rails/HasManyOrHasOneDependent
      -> { joins(:audit_action).where(audit_actions: {action: "create"}) },
      as: :auditable,
      class_name: "ActiveRecordAuditable::Audit",
      inverse_of: :auditable
    base.has_many :audits, # rubocop:disable Rails/HasManyOrHasOneDependent
      as: :auditable,
      inverse_of: :auditable

    base.after_create do
      create_audit!(action: :create)
    end

    base.after_update do
      create_audit!(action: :update)
    end

    base.after_destroy do
      create_audit!(action: :destroy, audited_changes: nil)
    end
  end

  def create_audit!(action:, audited_changes: saved_changes_for_audit, extra_liquid_variables: nil, user: nil)
    ActiveRecordAuditable::Audit.create!(
      audit_action: find_or_create_auditable_action(action),
      audit_auditable_type_id: find_or_create_auditable_type.id,
      audited_changes:,
      auditable_id: id,
      auditable_type: self.class.name,
      extra_liquid_variables:,
      user:
    )
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
