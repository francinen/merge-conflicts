{CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'
{GitBridge} = require './git-bridge'
handleErr = require './error-view'

module.exports =
class ResolverView extends View

  @content: (editor) ->
    @div class: 'overlay from-top resolver', =>
      @div class: 'block text-highlight', "We're done here"
      @div class: 'block', =>
        @div class: 'block text-info', =>
          @text "You've dealt with all of the conflicts in this file."
        @div class: 'block text-info', =>
          @span outlet: 'actionText', 'Save and stage'
          @text ' this file for commit?'
      @div class: 'pull-left', =>
        @button class: 'btn btn-primary', click: 'dismiss', 'Maybe Later'
      @div class: 'pull-right', =>
        @button class: 'btn btn-primary', click: 'resolve', 'Stage'

  initialize: (@editor) ->
    @disposables = new CompositeDisposable()

    @refresh()
    @editor.onDidSave => @refresh()

    @disposables.add atom.commands.add @element, 'merge-conflicts:quit', => @dismiss()

  getModel: -> null

  relativePath: -> atom.project.getRepositories()[0].relativize @editor.getUri()

  refresh: ->
    GitBridge.isStaged @relativePath(), (err, staged) =>
      return if handleErr(err)

      modified = @editor.isModified()

      needsSaved = modified
      needsStaged = modified or not staged

      unless needsSaved or needsStaged
        @hide 'fast', -> @remove()
        atom.emit 'merge-conflicts:staged', file: @editor.getUri()
        return

      if needsSaved
        @actionText.text 'Save and stage'
      else if needsStaged
        @actionText.text 'Stage'

  resolve: ->
    @editor.save()
    GitBridge.add @relativePath(), (err) =>
      return if handleErr(err)

      @refresh()

  dismiss: ->
    @hide 'fast', => @remove()
