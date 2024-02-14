class ActiveRecordAuditable::AuditAuditableType < ApplicationRecord
  self.table_name = "audit_auditable_types"

  has_many :audits, class_name: "ActiveRecordAuditable::Audit", dependent: :restrict_with_error
end
