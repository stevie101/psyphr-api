module AdminHelper
  def days_left(not_after)
    pluralize((( not_after - Time.now ) / 60 / 60 / 24 ).round(0), 'day')
  end
end
