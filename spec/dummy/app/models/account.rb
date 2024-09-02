class Account < ApplicationRecord
  include ActiveRecordAuditable::Audited

  has_many :projects, dependent: :destroy
end
