uuid = require 'node-uuid'


# Class
# -----

# `RoqServiceMessage` represents data wrapped in a
# standard format for passing over tcp between applications.

class RoqServiceMessage

  # Constructor
  constructor: (endpoint,data,transactionId,options)->

    # Set transaction id if one if not provided
    transactionId ?= uuid.v1().replace /\-/ig, ''

    # Save `encoding` option
    {@encoding} = options if options

    # Define enumerable `data` getter
    Object.defineProperty @, 'data',
      enumerable: true
      get: ()->
        data

    # Define enumerable `endpoint` getter
    Object.defineProperty @, 'endpoint',
      enumerable: true
      get: ()->
        endpoint

    # Define enumerable `transactionId` getter
    Object.defineProperty @, 'transactionId',
      enumerable: true
      get: ()->
        transactionId

    # Define enumerable `message` getter
    Object.defineProperty @, 'message',
      enumerable: true
      get: ()->
        @._wrap data

  # Wrap data with message envelope
  _wrap: (data=@data)->
    transaction: @.transactionId
    data: data
    time: Date.now()
    endpoint: @.endpoint

  # Encode `message` property
  encode: ->
    RoqServiceMessage.encode @message



# Static Methods
# --------------

# `decode`
RoqServiceMessage.decode = (data)->
  JSON.parse data.toString('utf-8')

# `encode`
RoqServiceMessage.encode = (data)->
  JSON.stringify data


# `parse`
RoqServiceMessage.parse = (buffer,data)->
  transactions = []
  buffer += data
  while true
    buff_pointer = buffer.indexOf RoqServiceMessage.EOT
    if buff_pointer isnt -1
      transaction = buffer.substring 0, buff_pointer + 2
      buffer = buffer.substring buff_pointer + 2
      try
        transactions.push RoqServiceMessage.decode transaction.trim()
      catch err
        buffer = ''
        return;

    else
      break

  transactions




# End of Transmission marker
RoqServiceMessage.EOT = "\r\n"


# Export the `RoqServiceMessage` class
module.exports = RoqServiceMessage
