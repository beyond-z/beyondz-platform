module ApplicationHelper
  # detemine the layout name of the current request (application, admin, etc...)
  def current_layout
    layout = controller.send(:_layout)
    if layout.instance_of? String
      layout
    else
      File.basename(layout.identifier).split('.').first
    end
  end

  def linkify_text(text)
    return text if text.nil?
    text = text.gsub("&", "&amp;")
    text = text.gsub("<", "&lt;")
    text = text.gsub(">", "&gt;")
    text = text.gsub("\"", "&quot;")
    text = text.gsub("\n", "<br />\n")
    text = text.gsub(URI.regexp, "<a target=\"_BLANK\" href=\"\\0\">\\0</a>")
    text.html_safe
  end

  def censor_email(email)
    return email if email.blank?

    parts = email.split('@')

    thing = parts[0]

    thing = thing[0 .. thing.length/4] + "***" + thing[-(thing.length/4 + 1) .. -1]

    parts[0] = thing

    return parts.join('@')
  end

  # for displaying phone numbers, grouping the digits makes it easier to read
  def format_phone_for_display(phone)
    return phone if phone.blank?
    # first normalize it
    phone = phone.gsub(/[^0-9]/, '')
    # then display it in common US style
    "(#{phone[-10 ... -7]}) #{phone[-7 ... -4]}-#{phone[-4 ... -1]}#{phone[-1]}"
  end

  def nav_button(text, path, className = '')
    c = className
    if request.path == path
      c += ' active'
    end

    ('<li>' + (link_to text, path, :class => c) + '</li>').html_safe
  end

  def join_us_button
    '<div class="apply-button">'.html_safe +
      link_to(
        '<div class="apply-icon"></div><div class="apply-text">JOIN US</div>'.html_safe,
        new_user_path
      ) +
      '</div>'.html_safe
  end

  def join_us_button_large
    '<span class="apply-button-lg">'.html_safe +
      link_to(
        '<div class="apply-icon"></div><br /><span class="apply-text">JOIN US</span>'.html_safe,
        new_user_path
      ) +
      '</span>'.html_safe
  end

  def light_page_jump(label, anchor)
    '<div class="page-jump">'.html_safe +
      link_to(
        '<div class="jump-icon"></div><div class="jump-text">'.html_safe +
        label + '</div>'.html_safe, "##{anchor}"
      ) +
      '</div>'.html_safe
  end

  def learn_more_link(about, url)
    '<div class="learn-more-link">'.html_safe +
      link_to(
        '<div class="learn-more-text"><div class="learn-more-icon"></div>Learn more about '.html_safe +
        about + '</div>'.html_safe, url
      ) +
      '</div>'.html_safe
  end

    def checked_if_in_array(param, item, alternative_string = nil)
    if params[param]
      params[param].each do |p|
        return 'checked="checked"'.html_safe if p == item
      end
    end
    if alternative_string
      alternative_string.split(';').each do |p|
        return 'checked="checked"'.html_safe if p == item
      end
    end
    ''
  end

  def value_after_array(param, item, alternative_string = nil)
    return_next = false
    if params[param]
      params[param].each do |p|
        return p if return_next
        return_next = true if p == item
      end
    end
    if alternative_string
      alternative_string.split(';').each do |p|
        return p if return_next
        return_next = true if p == item
      end
    end
    
  # Generate standard-sized Bootstrap modal HTML
  # Pass HTML ID and allowable options (defined in modal_options())
  # Most common options include title, content and footer
  def modal(id, opts = {})
    modal_html(id, opts)
  end

  # Generate large Bootstrap modal HTML
  # Pass HTML ID and allowable options (defined in modal_options())
  # Most common options include title, content and footer
  def large_modal(id, opts = {})
    opts = { large: true }.merge(opts)
    modal_html(id, opts)
  end

  # Generate small Bootstrap modal HTML
  # Pass HTML ID and allowable options (defined in modal_options())
  # Most common options include title, content and footer
  def small_modal(id, opts = {})
    opts = { small: true }.merge(opts)
    modal_html(id, opts)
  end

  class PermissionDenied < StandardError
  end

  private

  # See below for options
  def modal_options(opts = {})
    {
      title: '',
      content: '',
      footer: '<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>',
      close_button: true,
      small: false,
      large: false
    }.merge(opts)
  end

  # Define reusable and dynamic Bootstrap modal content
  # Pass HTML ID and allowable options (defined in modal_options())
  def modal_html(id, opts = {})
    options = modal_options(opts)

    size = ''
    if options[:small]
      size = ' modal-sm'
    elsif options[:large]
      size = ' modal-lg'
    end

    html = ''
    html += '<div class="modal fade" id="' + id + '" tabindex="-1"
      role="dialog" aria-labelledby="' + id + '-label" aria-hidden="true">'
    html += '<div class="modal-dialog' + size + '">'
    html += '<div class="modal-content">'
    html += '<div class="modal-header">'
    if options[:close_button]
      html += '<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>'
    end
    html += '<h4 class="modal-title" id="' + id + '-label">' + options[:title] + '</h4>'
    html += '</div>'
    html += '<div class="modal-body">' + options[:content] + '</div>'
    html += '<div class="modal-footer">' + options[:footer] + '</div>'
    html += '</div>'
    html += '</div>'
    html += '</div>'

    html.html_safe
  end
end
