{RoqServiceMessage} = require '../index'

describe 'RoqServiceMessage', ()->

  message = new RoqServiceMessage '/', test: true

  it 'should save data', (done)->

    (message.data).should.be.ok
    message.data.should.have.property 'test', true

    done()


  it 'should wrap data in message object', (done)->

    message.message.should.have.properties ['data','time']

    done()

  it 'should encode message data as JSON String', (done)->

    encoded_message = message.encode()
    encoded_message.should.be.an.instanceof String

    encoded_message = RoqServiceMessage.encode message.data
    encoded_message.should.be.an.instanceof Object

    done()

  it 'should decode message ', (done)->

    encoded_message = message.encode()
    decoded_message = RoqServiceMessage.decode encoded_message

    decoded_message.should.have.properties ['data','time']

    done()
