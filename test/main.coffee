# coffeelint: disable=max_line_length

{ change, check, responsive, unresponsive, pong, drop } = Monitor.eventNames

uri = 'http://localhost:9333'

Server = (times = 1) ->
  nock(uri).get('/').times(times).reply(200)

ServerError = (times = 1) ->
  nock(uri).get('/').times(times).reply(500, { message: "Exceeded capacity!" })

monitor = Monitor.create(uri, 200)






describe 'uri-monitor', ->
  @slow 1000

  describe '.observe()', ->

    it 'starts the monitor, issuing HTTP GET requests against a given URI.', ->
      server = Server()

      monitor
        .take 1
        .map ({ data: { isResponsive }}) -> isResponsive
        .observe a.eq true
        .then server.done



  describe 'the first check result causes four events', ->

    it 'can be check / change, where change is pong', ->
      server = Server()
      events = [check, change]

      monitor
        .take events.length
        .observe ({ type }) -> a.eq events.shift(), type
        .then server.done


    it 'can be check / change, where change is drop', ->
      events = [check, change]

      monitor
        .take events.length
        .observe ({ type }) -> a.eq events.shift(), type



  describe 'the nth check result', ->

    it 'can be check, without change, in pong state', ->
      server = Server(2)
      events = [check]

      monitor
        .skip 2
        .take events.length
        .observe ({ type }) -> a.eq events.shift(), type
        .then server.done

    it 'can be check, without change, in drop state ', ->
      events = [check]

      monitor
        .skip 2
        .take events.length
        .observe ({ type }) -> a.eq events.shift(), type

    it 'can be check / change, where change is drop', ->
      server = Server(1)
      events = [check, change]

      monitor
        .skip 2
        .take events.length
        .observe ({ type }) -> a.eq events.shift(), type
        .then server.done

    it 'can be check / change, where change is pong', ->
      events = [check, change]

      P.delay(1).then => @server = Server()

      monitor
        .skip 2
        .take events.length
        .observe ({ type }) -> a.eq events.shift(), type
        .then => @server.done()



  describe 'sugar', ->

    it '.drops filters for checks that drop', ->
      events = [check, check, check]

      monitor
      .drops
      .take events.length
      .observe ({ type, data: { isResponsive } }) ->
        a.eq events.shift(), type
        a not isResponsive, 'is drop'

    it '.pongs filters for checks that pong', ->
      server = Server(3)
      events = [check, check, check]

      monitor
      .pongs
      .take events.length
      .observe ({ type, data: { isResponsive } }) ->
        a.eq events.shift(), type
        a isResponsive, 'is pong'
      .then server.done

    it '.downs filters for changes into responsive state', ->
      server = Server(1)
      events = [change]

      monitor
      .downs
      .take events.length
      .observe ({ type, data: { isResponsive } }) ->
        a.eq events.shift(), type
        a not isResponsive, 'is unresponsive state'
      .then server.done

    it '.ups filters for changes into responsive state', ->
      P.delay(300).then => @server = Server(1)
      events = [change]

      monitor
      .ups
      .take events.length
      .observe ({ type, data: { isResponsive } }) ->
        a.eq events.shift(), type
        a isResponsive, 'is responsive state'
      .then => @server.done



describe 'request failures', ->

  it 'on 500 response .result is a RequestError', ->
    server = ServerError()

    monitor
    .take 1
    .tap (d) -> console.log d.data.result.res
    .observe ({ data: { result }}) ->
      a.isString result.message
      a.isNumber result.status
      a.isObject result.body
      a.isObject result.res
    .then server.done


  it 'on ENOTFOUND .result is a NetworkError', ->

    Monitor
    .create('http://92hgd76120wm10.com', 200)
    .take 1
    .observe ({ data: { result }}) ->
      a.isString result.message
      a.eq 'object', typeof result.originalError
