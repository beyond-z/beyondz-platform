module EnrollmentsHelper
  def checked_if_in_array(param, item)
    if params[param]
      params[param].each do |p|
        return 'checked="checked"'.html_safe if p == item
      end
    end
    ''
  end
end
