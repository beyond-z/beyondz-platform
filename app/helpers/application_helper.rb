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


  def modal(id, opts={})
    opts = {}.merge(opts)
    modal_html(id, opts)
  end

  def large_modal(id, opts={})
    opts = {large: true}.merge(opts)
    modal_html(id, opts)
  end

  def small_modal(id, opts={})
    opts = {small: true}.merge(opts)
    modal_html(id, opts)
  end

  class PermissionDenied < Exception
  end

  private

    # define reusable and dynamic modal content
    def modal_html(id, opts={})
      options = {
        title: '',
        content: '',
        footer: '<button type="button" class="btn btn-default"
          data-dismiss="modal">Close</button>',
        close_button: true,
        small: false,
        large: false
      }

      options.merge!(opts)
      
      size = ''
      if options[:small]
        size = ' modal-sm'
      elsif options[:large]
        size = 'modal-lg'
      end

      html = ''
      html += '<div class="modal fade" id="' + id + '" tabindex="-1"
        role="dialog" aria-labelledby="' + id + '-label" aria-hidden="true">'
        html += '<div class="modal-dialog' + size + '">'
          html += '<div class="modal-content">'
            html += '<div class="modal-header">'
              if options[:close_button]
                html += '<button type="button" class="close"
                  data-dismiss="modal" aria-hidden="true">&times;</button>'
              end
              html += '<h4 class="modal-title" id="' + id + '-label">'
                html += options[:title]
              html += '</h4>'
            html += '</div>'
            html += '<div class="modal-body">'
              html += options[:content]
            html += '</div>'
            html += '<div class="modal-footer">'
              html += options[:footer]
            html += '</div>'
          html += '</div>'
        html += '</div>'
      html += '</div>'

      html.html_safe
    end

end
