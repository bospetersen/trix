#= require trix/controllers/attachment_editor_controller
#= require trix/controllers/image_attachment_editor_controller
#= require trix/views/document_view

{DOM} = Trix
editOperationLog = Trix.Logger.get("editOperations")

class Trix.DocumentController
  constructor: (@element, @document) ->
    @documentView = new Trix.DocumentView @document, {@element}

    DOM.on(@element, "focus", @didFocus)
    DOM.on(@element, "click", "a[contenteditable=false]", (e) -> e.preventDefault())
    DOM.on(@element, "click", "figure.attachment", @didClickAttachment)

  didFocus: =>
    @delegate?.documentControllerDidFocus?()

  didClickAttachment: (event, target) =>
    attachment = @findAttachmentForElement(target)
    @delegate?.documentControllerDidSelectAttachment?(attachment)

  render: ->
    editOperationLog.time?("DocumentController#render")
    @delegate?.documentControllerWillRender?()
    @documentView.render()
    @reinstallAttachmentEditor()
    @delegate?.documentControllerDidRender?()
    editOperationLog.timeEnd?("DocumentController#render")

  rerenderViewForObject: (object) ->
    @documentView.invalidateViewForObject(object)
    @render()

  focus: ->
    @documentView.focus()

  getBlockElements: ->
    @documentView.getBlockElements()

  # Attachment editor management

  installAttachmentEditorForAttachment: (attachment) ->
    return if @attachmentEditor?.attachment is attachment
    return unless element = @findElementForAttachment(attachment)
    @uninstallAttachmentEditor()

    controller = if attachment.isImage()
      Trix.ImageAttachmentEditorController
    else
      Trix.AttachmentEditorController

    @attachmentEditor = new controller attachment, element, @element
    @attachmentEditor.delegate = this

  uninstallAttachmentEditor: ->
    @attachmentEditor?.uninstall()

  reinstallAttachmentEditor: ->
    if @attachmentEditor
      attachment = @attachmentEditor.attachment
      @uninstallAttachmentEditor()
      @installAttachmentEditorForAttachment(attachment)

  # Attachment controller delegate

  didUninstallAttachmentEditor: ->
    delete @attachmentEditor

  attachmentEditorDidRequestUpdatingAttachmentWithAttributes: (attachment, attributes) ->
    @delegate?.documentControllerWillUpdateAttachment?(attachment)
    @document.updateAttributesForAttachment(attributes, attachment)

  attachmentEditorDidRequestRemovalOfAttachment: (attachment) ->
    @delegate?.documentControllerDidRequestRemovalOfAttachment?(attachment)

  # Private

  findAttachmentForElement: (element) ->
    @document.getAttachmentById(Number(element.dataset.trixId))

  findElementForAttachment: (attachment) ->
    @documentView.findNodesForObject(attachment)?[0]
