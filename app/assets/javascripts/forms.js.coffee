$ ->
  handleFormErrors = (form, errors) ->
    form.find('input').removeClass('parsley-error parsley-success')

    $.each errors, (name, messages) ->
      input = form.find("input[name*='#{name}']")
      input.addClass('parsley-error')

  remoteForms = $('form[data-remote]')

  remoteForms.on 'ajax:success', (evt, data) ->
    form = $(@)
    inputs = form.find('input[type="text"],input[type="password"]')

    inputs.val('')
    inputs.blur()

    toastr[data.toast.type](data.toast.message) if data.toast

  remoteForms.on 'ajax:error', (evt, data) ->
    handleFormErrors($(@), data.responseJSON.errors)
