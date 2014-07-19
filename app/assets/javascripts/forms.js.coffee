$ ->
  handleFormErrors = (form, errors) ->
    form.find('input').removeClass('validation-error validation-success')

    $.each errors, (name, messages) ->
      input = form.find("input[name*='#{name}']")
      input.addClass('validation-error')

  remoteForms = $('form[data-remote]')

  remoteForms.on 'ajax:success', (evt, data) ->
    form = $(@)
    inputs = form.find('input[type="text"],input[type="password"]')
    handleFormErrors(form, {})

    inputs.val('')
    inputs.blur()

    toastr[data.toast.type](data.toast.message) if data.toast

  remoteForms.on 'ajax:error', (evt, data) ->
    handleFormErrors($(@), data.responseJSON.errors)
