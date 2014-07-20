$ ->
  $('.hidden-toast').each ->
    self = $(@)
    toastr[self.attr('data-type')](self.text())
