class ActiveRecordAuditable::Audit < ActiveRecordAuditable::BaseAudit
  self.table_name = "audits"

  belongs_to :audit_auditable_type, class_name: "ActiveRecordAuditable::AuditAuditableType"
  belongs_to :auditable, optional: true, polymorphic: true

  scope :where_type, ->(type) { joins(:audit_auditable_type).where(audit_auditable_types: {name: type}) }

  before_validation :set_audit_auditable_type

private

  def set_audit_auditable_type
    self.audit_auditable_type = ActiveRecordAuditable::AuditAuditableType.find_or_create_by!(name: auditable_type) if !audit_auditable_type && auditable_type?
  end
end
