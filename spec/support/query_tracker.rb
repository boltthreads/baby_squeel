module QueryTracker
  QUEUE = 'sql.active_record'

  def track_queries(&block)
    collected = []
    ActiveSupport::Notifications.subscribe(QUEUE) do |*event|
      collected << event.last[:sql]
    end
    yield
    collected
  ensure
    ActiveSupport::Notifications.unsubscribe(QUEUE)
  end
end
