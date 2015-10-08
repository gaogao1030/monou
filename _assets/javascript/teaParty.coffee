elements = {}
app_id = undefined
secret_key = undefined
msgTime = undefined
roomname = "teaParty-demo"
@chat_demo = {}
members = [
           {clientId: "leancloud",name:"leancloud"}
           {clientId: "1",name:"爱丽丝"}
           {clientId: "2",name:"亚瑟王"}
           {clientId: "3",name:"特斯拉"}
           {clientId: "4",name:"爱因斯坦"}
           {clientId: "5",name:"绅士君"}
           {clientId: "6",name:"超人"}
           {clientId: "7",name:"变态君"}
           {clientId: "8",name:"咖啡君"}
           {clientId: "9",name:"多啦A梦"}
           {clientId: "10",name:"金闪闪"}
          ]

start = (appid,secret_key) ->
  AV.initialize(appid,secret_key)
  roomname = "teaParty-demo"
  app_id = appid
  secret_key = secret_key
  get_element()
  get_conversation().then(
    (conv_id)->
      connect(roomname,conv_id,"leancloud").then(
        (rt,room) ->
          get_member(rt,room).then(
            (client_id)->
              close_connect(rt).then(
                ->
                  unless client_id == undefined
                    main(roomname,conv_id,client_id)
                  else
                    showLog('该茶会人已经满了,请过会来')
                  )
              )
      )
    (err)->
      console.log("Error: " + error.code + " " + error.message)
  )

connect = (roomname,conv_id,client_id)->
  rt = AV.realtime({
    appId: app_id
    clientId: roomname+":"+client_id
    secure: false
    auth: authFun
  })
  promise = new AV.Promise
  rt.on('open',->
    rt.room(conv_id,(obj)->
      if obj
        promise.resolve(rt,obj)
      else
        rt.room({
          name: roomname
          attr: {
            room_id: roomname
          }
          #transient: true #创建暂态对话
          members:
            [roomname+":leancloud"]
        },(obj)->
          conv_id = obj.id
          close_connect(rt).then(
            ->
              promise.resolve(rt,obj)
          )
        )
    )
  )
  return promise

close_connect = (rt)->
  promise = new AV.Promise
  rt.close()
  rt.on('close',->
    promise.resolve()
  )
  return promise

get_element = ->
  elements.body = $("body")
  elements.printWall = $("#print_wall")
  elements.sendMsgBtn = $("#basic-addon2")
  elements.vister_list = $("#vister_list")
  elements.inputSend = $("#input_send")

get_conversation = ->
  promise = new AV.Promise
  conv = AV.Object.extend('_conversation')
  q = new AV.Query(conv)
  q.equalTo('attr.room_id',roomname)
  q.find({
    success: (response) ->
      conv_id = response[0]?.id||"null"
      promise.resolve(conv_id)
    error: ()->
      promise.reject(err)
  })
  return promise

bindEvent = (rt,room)->
  elements = elements
  elements.body.on('keydown', (e)->
    pressEnter(e,room)
  )
  elements.sendMsgBtn.on('click', ->
    sendMsg(room)
  )
  $(document).on('click','.member',click_member)

click_member = (e) ->
  alert $(@).html()

rerender_members_list = (rt,client_id,data) ->
  vister_list = elements.vister_list
  vister_list.html("")
  range = [0..(parseInt(data.length/20)) ]
  _.each(range,(i)->
    p_data = data.slice(i*20,(i+1)*20)
    rt.ping(p_data, (list) ->
      _.each(list,(d)->
        d=originClientId(d)
        member = clientIdToMember(d)
        name = member.name
        name = member.name+"(我)" if d == client_id
        template = '<a href="javascript:void(0)"><div class="member" >' + name + '</div></a>'
        vister_list.append(template)
      )
    )
    if data.length > 50
      room.remove(data[1],->
        showLog('人数过多驱逐出去的是',data[1])
      )
  )


showLog = (msg, data, isBefore) ->
  if (data)
    msg = msg + '<span class="strong">' + encodeHTML(JSON.stringify(data)) + '</span>'
  printWall = $("#print_wall")[0]
  p = document.createElement('p')
  p.innerHTML = msg
  if (isBefore)
    printWall.insertBefore(p, printWall.childNodes[0])
  else
    printWall.appendChild(p)

pressEnter = (e,room)->
  if e.keyCode == 13
    sendMsg(room)

authFun = (options,callback) ->
  AV.realtime._tool.ajax({
    url: 'https://gaogao.avosapps.com/sign2',
    data: {
      client_id: options.clientId,
      conv_id: options.convId,
      members: options.members,
      action: options.action
    }
    method:'post'
  },callback)

encodeHTML=(source) ->
  return String(source)
    .replace(/&/g,'&amp;')
    .replace(/</g,'&lt;')
    .replace(/>/g,'&gt;')

sendMsg = (room)->
  elements = elements
  inputSend = elements.inputSend
  printWall = elements.printWall[0]
  msg = inputSend.val()
  if (!String(msg).replace(/^\s+/, '').replace(/\s+$/, ''))
    alert('请输入点文字！')
    return
  room.send({
      text: msg
  },
  {
      type: 'text'
  },
  (data)->
      inputSend.val('')
      showLog('（' + formatTime(data.t) + '）  自己： ', msg)
      printWall.scrollTop = printWall.scrollHeight
  )

getLog = (room)->
  promise  = new AV.Promise
  elements = elements
  printWall = elements.printWall[0]
  height = printWall.scrollHeight
  if (logFlag)
      return
  else
    # 标记正在拉取
    logFlag = true
  room.log({
    t: msgTime
  }
  (data)->
    logFlag = false
    # 存储下最早一条的消息时间戳
    l = data.length
    if(l)
      msgTime = data[0].timestamp
      printWall.scrollTop = printWall.scrollHeight - height
      data.reverse()
    _.each(data,(d)->
      showMsg(d, true)
    )

    promise.resolve()
  )
  return promise

showMsg = (data, isBefore, client_id) ->
  text = ''
  from = data.fromPeerId
  from_name = clientIdToMember(originClientId(from))?.name
  if(data.msg.type)
    text = data.msg.text
  else
    text = data.msg
  if(data.fromPeerId == client_id)
    from_name = '自己'
  if(String(text).replace(/^\s+/, '').replace(/\s+$/, ''))
    showLog('（' + formatTime(data.timestamp) + '）  ' + encodeHTML(from_name) + '： ', text, isBefore)



formatTime=(time)->
  date = new Date(time)
  return $.format.date(date,"yyyy-MM-dd hh:mm:ss")

main = (roomname,conv_id,client_id)->
  printWall = elements.printWall
  showLog("正在加入轻飘飘的下午茶时间，请等待。。。")

  connect(roomname,conv_id,client_id).then(
    (rt,room) ->
      bindEvent(rt,room)
      showLog('欢迎来到轻飘飘的下午茶时间')
      room.join(->
        getLog(room).then(
          ->
            printWall[0].scrollTop = printWall[0].scrollHeight
            showLog('已经加入，可以开始聊天。')
        )
      )
      room.receive((data)->
        printWall[0].scrollTop = printWall[0].scrollHeight
        if !msgTime
          msgTime = data.timestamp
        showMsg(data)
      )

      rt.on('reuse',->
        showLog("正在重新加入轻飘漂的下午茶时间")
      )

      rt.on('error',->
        showLog('好像有什么不对劲 请打开console 查看相关日志 ')
        console.log rt
      )

      rt.on('join',(res)->
        _.each(res.m, (m)->
          unless m == client_id
            member = clientIdToMember(originClientId(m))
            showLog(member.name + '加入下午茶')
            room.list((data)->
              rerender_members_list(rt,client_id,data) #拿到在线的成员列表最多20个
            )
        )
      )

      rt.on('left',(res)->
        console.log res
      )
  )


cleart_members = ->
  room.list((data)->
    room.remove(data,->
      console.log "clear_members"
    )
  )

get_online_members = (rt,room,opt={})->
  online_members = []
  promise = new AV.Promise
  room.list((data)->
    range = [0..(parseInt(data.length/20)) ]
    _.each(range,(i)->
      p_data = data.slice(i*20,(i+1)*20)
      rt.ping(p_data, (list) ->
        _.each(list,(d)->
          online_members.push d
        )
        #opt.callback(online_members) if opt.callback
        promise.resolve(online_members)
      )
    )
  )
  return timeoutPromise(promise,10000) #default 10 seconds


originClientId = (client_id)->
  if client_id != undefined and client_id.match(roomname) != null
    return client_id.slice(roomname.length+1)

clientIdToMember = (c_id)->
  member = _.findWhere(members,{clientId:c_id})


get_member = (rt,room)->
  promise = new AV.Promise
  get_online_members(rt,room).then(
    (online_members)->
      online_list = online_members.map((d)->
        return originClientId(d)
      )
      c_members = _.clone(members)
      _.each(online_list, (m)->
        member = clientIdToMember(m)
        c_members = _.without(c_members,member)
      )
      client_id = c_members[0]?.clientId
      promise.resolve(client_id)
  )
  return promise

timeoutPromise = (promise,ms) ->
  delayPromise = ->
    return new AV.Promise(
      (resolve) ->
        setTimeout(resolve,ms)
    )
  timeout_promise = delayPromise(ms).then(
    ->
      Promise.reject(new Error("请求超时"))
  )
  return AV.Promise.race([promise,timeout_promise])

@chat_demo.get_member = ->
  get_conversation().then(
    (conv_id)->
      connect("teaParty-demo",conv_id,"leancloud").then(
        (rt,conv) ->
          get_member(rt,conv).then(
            (client_id) ->
              console.log client_id
              close_connect(rt)
          )
      )
  )

@chat_demo.get_online_members = ->
  get_conversation().then(
    (conv_id)->
      connect("teaParty-demo",conv_id,"leancloud").then(
        (rt,conv)->
          get_online_members(rt,conv).then(
            (list) ->
              console.log list
              close_connect(rt)
          )
      )
  )

@chat_demo.get_conversation = get_conversation
@chat_demo.start = start
@chat_demo.clear_members= cleart_members
