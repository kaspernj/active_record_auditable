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
    dedicated_table_name = "#{base.table_name.singularize}_audits"
    dedicated_table_exists = __dedicated_table_exists?(base, dedicated_table_name)

    if dedicated_table_exists
      table_name = dedicated_table_name
      audit_class = __dedicated_audit_class(base, table_name)
      audit_class_name = "#{base.name}::Audit"
      inverse_of = base.model_name.param_key.to_sym
      as = inverse_of
    else
      table_name = "audits"
      audit_class = ActiveRecordAuditable::Audit
      audit_class_name = "ActiveRecordAuditable::Audit"
      inverse_of = :auditable
      as = :auditable
    end

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
      audit_class = self.class.reflections["audits"].klass
      audit_query = audit_class
        .select(1)
        .joins(:audit_action)
        .where(audit_actions: {action:})
        .where("#{audit_class.table_name}.auditable_id = #{base.table_name}.#{base.primary_key}")
        .limit(1)

      audit_query = audit_query.where(auditable_type: base.model_name.name) unless dedicated_table_exists
      where("NOT EXISTS (#{audit_query.to_sql})")
    }
  end

  def self.__dedicated_table_exists?(base, dedicated_table_name)
    ActiveRecordAuditable::Audited.__cached_audit_table_names.key?(dedicated_table_name)
  rescue ActiveRecord::StatementInvalid
    false
  end

  def self.__dedicated_audit_class(base, table_name)
    if base.const_defined?("Audit")
      base.const_get("Audit")
    else
      audit_class = Class.new(ActiveRecordAuditable::BaseAudit)
      audit_class.class_eval do
        self.table_name = table_name

        belongs_to base.model_name.param_key.to_sym, optional: true
        belongs_to :auditable, class_name: base.name, foreign_key: :"#{base.model_name.param_key}_id", optional: true

        def auditable_type
          self.class.reflections["auditable"].class_name
        end
      end

      base.const_set("Audit", audit_class)

      ActiveRecordAuditable::AuditAction.has_many(audit_class.model_name.plural.to_sym, class_name: audit_class.name)
      ActiveRecordAuditable::AuditAuditableType.has_many(audit_class.model_name.plural.to_sym, class_name: audit_class.name)

      audit_class
    end
  end

  def audit_monitor
    @@audit_monitor ||= Monitor.new # rubocop:disable Style/ClassVars
  end

  def create_audit!(action:, audited_changes: saved_changes_for_audit, **args)
    audit_data = {
      audit_action: find_or_create_auditable_action(action),
      audited_changes:
    }

    audit_class = self.class.reflections["audits"].klass

    if audit_class == ActiveRecordAuditable::Audit
      audit_data[:audit_auditable_type_id] = find_or_create_auditable_type.id
      audit_data[:auditable_id] = id
      audit_data[:auditable_type] = self.model_name.name
    else
      audit_data[:"#{self.class.model_name.param_key}_id"] = id
    end

    audit_class.create!(audit_data.merge(args))
  end

  def find_or_create_auditable_action(action)
    audit_monitor.synchronize do
      return ActiveRecordAuditable::AuditAction.find_or_create_by!(action:)
    end
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
