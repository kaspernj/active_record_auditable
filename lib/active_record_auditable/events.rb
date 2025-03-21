class ActiveRecordAuditable::Events
  def self.current
    @current ||= ActiveRecordAuditable::Events.new
  end

  def initialize
    reset
  end

  def call(type, action, args)
    @connections.dig(type, action)&.each do |blk|
      blk.call(**args)
    end
  end

  def connect(type, action, &blk)
    action = action.to_s
    type = type.to_s

    @connections[type] ||= {}
    @connections[type][action] ||= []
    @connections[type][action] << blk
  end

  def reset
    @connections = {}
  end
end
