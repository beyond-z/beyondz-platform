module EnrollmentsHelper
  def checked_if_in_array(param, item)
    if params[param]
      params[param].each do |p|
        return 'checked="checked"'.html_safe if p == item
      end
    end
    ''
  end

  def value_after_array(param, item)
    return_next = false
    if params[param]
      params[param].each do |p|
        return p if return_next
        return_next = true if p == item
      end
    end
    ''
  end
end
