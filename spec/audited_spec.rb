require "rails_helper"

describe "audited" do
  let(:account) { create :account, name: "Test account" }

  it "logs destroys" do
    account

    expect { account.destroy! }
      .to change(ActiveRecordAuditable::Audit, :count).by(1)

    created_destroy_audit = ActiveRecordAuditable::Audit.last!

    expect(created_destroy_audit).to have_attributes(
      action: "destroy",
      audited_changes: {
        "created_at" => instance_of(String),
        "id" => account.id,
        "name" => "Test account",
        "updated_at" => instance_of(String)
      },
      auditable_id: account.id,
      auditable_type: "Account"
    )
  end
end
