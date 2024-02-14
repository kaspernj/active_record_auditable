class ActiveRecordAuditable::AuditAction < ApplicationRecord
  self.table_name = "audit_actions"

  has_many :audits, class_name: "ActiveRecordAuditable::Audit", dependent: :restrict_with_error
end
