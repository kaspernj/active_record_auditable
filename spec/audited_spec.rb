require "rails_helper"

describe "audited" do
  let(:account) { create :account, name: "Test account" }
  let(:project) { create :project, name: "Test project" }

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

  it "creates audits in a dedicated table" do
    expect { project }.to change(Project::Audit, :count).by(1)

    expect(project.create_audit).to have_attributes(
      action: "create",
      project: project,
      project_id: project.id
    )

    found_create_audit = project.audits.where_action(:create).first!
    expect(found_create_audit).to have_attributes(
      action: "create",
      project: project,
      project_id: project.id
    )
  end

  describe "#without_audit" do
    it "filters out audits with a specific audit" do
      project1 = create(:project)
      project1.create_audit!(action: "custom_audit")

      project2 = create(:project)
      project2.create_audit!(action: "another_audit")

      projects = Project.without_audit(:another_audit)

      expect(projects).to eq [project1]
    end
  end
end
