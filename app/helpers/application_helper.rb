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

  # generate standard-sized modal html
  def modal(id, opts = {})
    modal_html(id, opts)
  end

  # generate large modal html
  def large_modal(id, opts = {})
    opts = { large: true }.merge(opts)
    modal_html(id, opts)
  end

  # generate small modal html
  def small_modal(id, opts = {})
    opts = { small: true }.merge(opts)
    modal_html(id, opts)
  end

  class PermissionDenied < Exception
  end

  private

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

    # define reusable and dynamic modal content
    def modal_html(id, opts = {})

      options = modal_options(opts)

      size = ''
      if options[:small]
        size = ' modal-sm'
      elsif options[:large]
        size = ' modal-lg'
      end

      html = ''
      html += '<div class="modal fade" id="' + id + '" tabindex="-1" role="dialog" aria-labelledby="' + id + '-label" aria-hidden="true">'
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
