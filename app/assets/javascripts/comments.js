$(document).ready(function() {
  var attachment_button = $('.attachment #attachment-button');
  var select_document = $('.attachment #select-document');
  var select_image = $('.attachment #select-image');
  var document_type = $('.attachment .document');
  var image_type = $('.attachment .image');

  attachment_button.click(function() {
    var select_type = $('#select-type');

    if(attachment_button.hasClass('active'))
    {
      document_type.hide();
      image_type.hide();
      select_document.removeClass('active');
      select_image.removeClass('active');
      select_type.hide();
    }
    else
    {
      select_type.show();
    }
  });

  select_document.click(function() {
    document_type.show();
    image_type.hide();
  })
  select_image.click(function() {
    image_type.show();
    document_type.hide();   
  })
});