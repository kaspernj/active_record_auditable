module ActiveRecordAuditable::Audited
  def self.__cached_audit_table_names
    @__cached_audit_table_names ||= begin
      result = {}
      ActiveRecordAuditable::Audit.connection.tables.filter { |table_name| table_name.ends_with?("_audits") }.each do |table_name|
        result[table_name] = true
      end
      result
    end
  end

  def self.included(base)
    table_data = ActiveRecordAuditable::TableData.execute!(model_class: base)
    table_name = table_data.fetch(:table_name)
    audit_class = table_data.fetch(:audit_class)
    audit_class_name = table_data.fetch(:audit_class_name)
    inverse_of = table_data.fetch(:inverse_of)
    as = table_data.fetch(:as)
    dedicated_table_name = table_data.fetch(:dedicated_table_name)
    dedicated_table_exists = table_data.fetch(:dedicated_table_exists)

    base.has_one :create_audit, # rubocop:disable Rails/HasManyOrHasOneDependent
      -> { joins(:audit_action).where(audit_actions: {action: "create"}) },
      as: as,
      class_name: audit_class_name,
      inverse_of: inverse_of
    base.has_many :audits, # rubocop:disable Rails/HasManyOrHasOneDependent
      as: as,
      class_name: audit_class_name,
      inverse_of: inverse_of

    base.has_one :create_audit, # rubocop:disable Rails/HasManyOrHasOneDependent
      -> { joins(:audit_action).where(audit_actions: {action: "create"}) },
      class_name: audit_class_name,
      inverse_of: inverse_of
    base.has_many :audits, # rubocop:disable Rails/HasManyOrHasOneDependent
      class_name: audit_class_name,
      inverse_of: inverse_of

    base.after_create do
      create_audit!(action: :create)
    end

    base.after_update do
      create_audit!(action: :update)
    end

    base.after_destroy do
      create_audit!(action: :destroy, audited_changes: attributes)
    end

    base.scope :without_audit, lambda { |action|
      audit_class = base.reflections["audits"].klass
      audit_foreign_key = base.reflections["audits"].foreign_key

      audit_query = audit_class
        .select(1)
        .joins(:audit_action)
        .where(audit_actions: {action:})
        .where("#{audit_class.table_name}.#{audit_foreign_key} = #{base.table_name}.#{base.primary_key}")
        .limit(1)

      audit_query = audit_query.where(auditable_type: base.model_name.name) unless dedicated_table_exists
      where("NOT EXISTS (#{audit_query.to_sql})")
    }
  end

  def audit_monitor
    @@audit_monitor ||= Monitor.new # rubocop:disable Style/ClassVars
  end

  def create_audit!(action:, audited_changes: saved_changes_for_audit, **args)
    audit_data = {
      audit_action: ActiveRecordAuditable::FindOrCreateAction.execute!(action:),
      audited_changes:
    }

    audit_class = self.class.reflections["audits"].klass
    auditable_type = self.model_name.name

    if audit_class == ActiveRecordAuditable::Audit
      audit_data[:audit_auditable_type_id] = find_or_create_auditable_type.id
      audit_data[:auditable_id] = id
      audit_data[:auditable_type] = auditable_type
    else
      audit_data[:"#{self.class.model_name.param_key}_id"] = id
    end

    audit = audit_class.create!(audit_data.merge(args))

    ActiveRecordAuditable::Events.current.call(auditable_type.to_s, action.to_s, {audit:})
  end

  def find_or_create_auditable_type
    audit_monitor.synchronize do
      return ActiveRecordAuditable::AuditAuditableType.find_or_create_by!(name: self.class.name)
    end
  end

  def saved_changes_for_audit
    saved_changes_for_audit = {}
    saved_changes.each do |attribute_name, from_and_to|
      saved_changes_for_audit[attribute_name] = from_and_to[1]
    end
    saved_changes_for_audit
  end
end
