$ ->
  ##
  # Remote forms
  handleFormErrors = (form, errors) ->
    form.find('input').removeClass('validation-error validation-success')

    $.each errors, (name, messages) ->
      input = form.find("input[name*='#{name}']")
      input.addClass('validation-error')

  handleResponse = (response) ->
    toastr[response.toast.type](response.toast.message) if response.toast
    location.reload(true) if response.reload

  remoteForms = $('form[data-remote]')

  remoteForms.on 'ajax:success', (evt, data) ->
    form = $(@)
    inputs = form.find('input[type="text"],input[type="password"]')
    handleFormErrors(form, {})
    inputs.val('')
    inputs.blur()
    handleResponse(data)

  remoteForms.on 'ajax:error', (evt, data) ->
    handleResponse(data)
    handleFormErrors($(@), data.responseJSON.errors)

  ##
  # Auto select on focus fields
  $('input[data-selectonfocus]').selectOnFocus()
