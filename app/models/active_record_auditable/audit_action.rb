class ActiveRecordAuditable::AuditAction < ApplicationRecord
  has_many :audits, class_name: "ActiveRecordAuditable::Audit", dependent: :restrict_with_error
end
