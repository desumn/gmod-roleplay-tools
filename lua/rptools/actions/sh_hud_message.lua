if SERVER then
  RPTools.Actions.Server.RegisterClientAction("hud_message", function(params)
    return istable(params) and isstring(params.message) and RPTools.Utilities.IsNumber(params.duration)
  end, function(params)
    return "hud message: " .. params.message .. "(duration: " .. params.duration .. ")"
  end)
end

if CLIENT then
  local messages = {}
  RPTools.Actions.Client.RegisterAction("hud_message", function(params)
    table.insert(messages, { duration = params.duration, text = params.message })
    return
  end)

  local fadeDuration = 0.5

  surface.CreateFont("RPToolsHUDMessageFont", {
    font = "Roboto",
    extended = true,
    size = 28,
    weight = 700,
    antialias = true,
  })

  hook.Add("HUDPaint", "RPTools_HUD_Message", function()
    if table.IsEmpty(messages) then
      return
    end
    local message = messages[1]

    local time = CurTime()

    if not message.startTime then
      message.startTime = time
      message.stopTime = time + message.duration
    end

    if time > message.stopTime then
      table.remove(messages, 1)
      return
    end

    local timeElapsed = time - message.startTime
    local timeLeft = message.stopTime - time

    local color = color_black
    local alpha = 255

    if timeElapsed <= fadeDuration then
      alpha = math.Clamp((timeElapsed / fadeDuration) * 255, 0, 255)
    elseif timeLeft <= fadeDuration then
      alpha = math.Clamp((timeLeft / fadeDuration) * 255, 0, 255)
    end

    surface.SetFont("HUDMessageFont")
    local textWidth, textHeight = surface.GetTextSize(message.text)

    local paddingX = 20
    local paddingY = 12
    local bandWidth = 6

    local boxWidth = textWidth + (paddingX * 2) + bandWidth
    local boxHeight = textHeight + (paddingY * 2)

    local boxX = (ScrW() / 2) - (boxWidth / 2)
    local boxY = ScrH() - boxHeight - 40

    surface.SetDrawColor(12, 12, 16, alpha * 0.95)
    surface.DrawRect(boxX, boxY, boxWidth, boxHeight)

    local bandColor = Color(0, 230, 255)
    surface.SetDrawColor(bandColor.r, bandColor.g, bandColor.b, alpha)
    surface.DrawRect(boxX, boxY, bandWidth, boxHeight)

    local textX = boxX + bandWidth + paddingX
    local textY = boxY + paddingY

    draw.SimpleText(
      message.text,
      "RPToolsHUDMessageFont",
      textX + 2,
      textY + 2,
      Color(0, 0, 0, alpha * 0.8),
      TEXT_ALIGN_LEFT,
      TEXT_ALIGN_TOP
    )

    local couleurTexte = Color(240, 235, 230)
    draw.SimpleText(
      message.text,
      "RPToolsHUDMessageFont",
      textX,
      textY,
      ColorAlpha(couleurTexte, alpha),
      TEXT_ALIGN_LEFT,
      TEXT_ALIGN_TOP
    )
  end)
end
