class Project < ApplicationRecord
  include ActiveRecordAuditable::Audited

  belongs_to :account

  validates :name, presence: true
end
