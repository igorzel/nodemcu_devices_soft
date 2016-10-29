dofile("settings.lua")

connected=false

function log(str)
  if LOG_SERIAL then
    print("DBG: "..str)
  end
  if LOG_MQTT and connected then
    m:publish("/"..MQTT_CLIENT.."/log",str,0,0)
  end
end

function subscribe(topic)
  log("Subscribe to "..topic)
  m:subscribe("/"..MQTT_CLIENT.."/"..topic,0,nil)
end

function send(topic,data)
  if connected then
    log("send("..topic..","..data..")")
    m:publish("/"..MQTT_CLIENT.."/"..topic,data,0,0)
  end
end

log("Start")
dofile(MAIN_TASK_FILE)

m=mqtt.Client(MQTT_CLIENT,60,"","")
m:lwt("/"..MQTT_CLIENT.."/net", "OFF",0,0)

m:on("connect",function(m)
  log("mqtt connected")
  connected=true
  m:publish("/"..MQTT_CLIENT.."/net","ON",0,0)
  subscribe("settings/log_mqtt")
  onConnect()
end)

m:on("offline",function(conn)
  connected=false
  log("mqtt disconnected")
end)

m:on("message",function(client,topic,data)
  log("Received: \""..topic.."\" \""..data.."\"")
  subtopic = topic:match("/"..MQTT_CLIENT.."/([^,]+)")
  if subtopic=="settings/log_mqtt" then
    LOG_MQTT=(data=="ON")
  else
    onReceive(subtopic,data)
  end
end)

wifi.setmode(wifi.STATION)
wifi.sta.eventMonReg(wifi.STA_CONNECTING,function(previous_State)
  if(previous_State==wifi.STA_GOTIP) then
    connected=false
    m:close()
    log("Lost WiFi connection...")
  else
    log("STATION_CONNECTING")
  end
end)
wifi.sta.eventMonReg(wifi.STA_APNOTFOUND,function() log("STATION_NO_AP_FOUND") end)
wifi.sta.eventMonReg(wifi.STA_GOTIP,function()
  log("STATION_GOT_IP")
  m:connect(MQTT_HOST,MQTT_PORT,0,1)
end)
wifi.sta.eventMonStart()
wifi.sta.config(WIFI_SSID, WIFI_PASSWORD)
wifi.sta.autoconnect(1)
