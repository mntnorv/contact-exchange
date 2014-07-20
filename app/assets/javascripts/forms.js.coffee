$ ->
  ##
  # Ladda buttons
  $('.ladda-button').each ->
    self = $(@)
    ladda = self.ladda()
    self.data('ladda', ladda)

  ##
  # Remote forms
  remoteForms = $('form[data-remote]')
  remoteForms.each ->
    form = $(@)
    inputs = form.find('input[type="text"],input[type="password"]')
    submit = form.find('button[type="submit"]')
    ladda = submit.ladda() if submit.hasClass('ladda-button')

    handleFormErrors = (errors) ->
      form.find('input').removeClass('validation-error validation-success')

      $.each errors, (name, messages) ->
        input = form.find("input[name*='#{name}']")
        input.addClass('validation-error')

    handleComplete = (response) ->
      if response.reload
        location.reload(true)
        false
      else
        ladda.ladda('stop') if ladda
        toastr[response.toast.type](response.toast.message) if response.toast
        handleFormErrors(response.errors or {})
        true

    form.submit ->
      ladda.ladda('start') if ladda

    form.on 'ajax:success', (evt, data) ->
      if handleComplete(data)
        inputs.val('')
        inputs.blur()

    form.on 'ajax:error', (evt, data) ->
      handleComplete(data.responseJSON)

  ##
  # Auto select on focus fields
  $('input[data-selectonfocus]').selectOnFocus()
