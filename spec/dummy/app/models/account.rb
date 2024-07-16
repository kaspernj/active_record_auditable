class Account < ApplicationRecord
  include ActiveRecordAuditable::Audited
end
