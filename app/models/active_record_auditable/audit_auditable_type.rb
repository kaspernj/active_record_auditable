class ActiveRecordAuditable::AuditAuditableType < ApplicationRecord
  has_many :audits, class_name: "ActiveRecordAuditable::Audit", dependent: :restrict_with_error
end
