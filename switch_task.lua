BUTTON=3
LED=4
gpio.mode(BUTTON,gpio.INPUT,gpio.PULLUP)
gpio.mode(LED,gpio.OUTPUT)
gpio.write(LED, gpio.LOW)

state=gpio.LOW

function onConnect()
  subscribe("command")
  send("state",state)
end

function onReceive(topic,data)
  if topic=="command" then
    if data=="ON" then state=gpio.HIGH else state=gpio.LOW end
    gpio.write(LED, state)
  end
end

gpio.trig(BUTTON,"down",function(level)
  if state==gpio.LOW then state=gpio.HIGH else state=gpio.LOW end
  log("State changed to "..state)
  gpio.write(LED, state)
  send("state",state)
end)
