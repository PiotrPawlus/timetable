#= require momentjs
#= require momentjs-business
#= require momentjs/locale/pl
#= require jquery
#= require timer.jquery
#= require i18next
#= require i18n/translations
#= require URIjs
#= require bootstrap-sprockets
#= require semantic-ui
#= require lodash

$ ->
  $('body').on 'click', '.icon.wait', ->
    $('#modal-info').addClass('active visible')

  $('body').on 'click', '#modal-info .button.cancel, .modal-backdrop', ->
    $('#modal-info').removeClass('active visible')

  $('body').on 'click', (e) ->
    klass  = $(e.target).attr('class') || ''
    parent = $(e.target).parent().attr('class') || ''
    if !(klass.match('dropdown') || klass.match('menu') || parent.match('dropdown'))
      $('.dropdown .menu').hide()

  $('body').on 'click', '.dropdown', ->
    $(this).find('.menu').toggle()

  $('body').on 'click', '#generate, .modal-backdrop', ->
    $('#modal').toggle()

  $(document).on 'push-entry', (e) ->
    $("#work-time-#{e.detail.id}").addClass('new')
    setTimeout( ->
      $("#work-time-#{e.detail.id}").removeClass('new')
    , 600)

  $(document).on 'edit-entry', (e) ->
    $("#work-time-#{e.detail.id}").addClass('hotline-bling')
    setTimeout( ->
      $("#work-time-#{e.detail.id}").removeClass('hotline-bling')
    , 2500)
