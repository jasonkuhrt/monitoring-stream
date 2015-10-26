# coffeelint: disable=max_line_length

uri = 'http://localhost:9333'
isChange = F.propEq 'type', 'change'
isCheck = F.propEq 'type', 'check'
getIsResponsive = F.path(['data', 'isResponsive'])
Server = (times = 1) ->
  nock(uri).get('/').times(times).reply(200)






describe 'uri-monitor', ->
  @slow 1000

  beforeEach ->
    @monitor = Monitor(uri, 200)
    @Monitor = -> Monitor(uri, 200)



  describe '.observe()', ->

    it 'starts the monitor, issuing HTTP GET requests against a given URI.', ->
      server = Server()

      @monitor
        .take 1
        .map getIsResponsive
        .observe a.eq true
        .then server.done



  describe 'the first check result causes four events', ->

    it 'can be check / pong / change / responsive', ->
      server = Server()
      events = ['check', 'pong', 'change', 'responsive']

      @monitor
        .take events.length
        .observe (event) -> a.eq events.shift(), event.type
        .then server.done


    it 'can be check / drop / change / unresponsive', ->
      events = ['check', 'drop', 'change', 'unresponsive']

      @monitor
        .take events.length
        .observe (event) -> a.eq events.shift(), event.type



  describe 'the nth check result', ->

    it 'can be check / pong without change events', ->
      server = Server(2)
      events = ['check', 'pong']

      @monitor
        .skip 4
        .take events.length
        .observe (event) -> a.eq events.shift(), event.type
        .then server.done

    it 'can be check / drop without change events', ->
      events = ['check', 'drop']

      @monitor
        .skip 4
        .take events.length
        .observe (event) -> a.eq events.shift(), event.type

    it 'can be check / drop / change / unresponsive', ->
      server = Server(1)
      events = ['check', 'drop', 'change', 'unresponsive']

      @monitor
        .skip 4
        .take events.length
        .observe (event) -> a.eq events.shift(), event.type
        .then server.done

    it 'can be check / pong / change / responsive', ->
      events = ['check', 'pong', 'change', 'responsive']

      P.delay(1).then => @server = Server()

      @monitor
        .skip 4
        .take events.length
        .observe (event) -> a.eq events.shift(), event.type
        .then => @server.done()
