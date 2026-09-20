local Lighting = game:GetService("Lighting")

local Notification = {}

function Notification.new(ctx)
	local C = ctx.C
	local make, frame, text, round = ctx.make, ctx.frame, ctx.text, ctx.round
	local tween, prep, fade = ctx.tween, ctx.prep, ctx.fade
	local root, cfg, Images = ctx.root, ctx.cfg, ctx.images
	local FONT_BOLD = ctx.FONT_BOLD

	local NOTIF_W, NOTIF_H = cfg.NOTIF_W, cfg.NOTIF_H
	local NOTIF_TRANSPARENCY = cfg.NOTIF_TRANSPARENCY
	local NOTIF_COLOR = cfg.NOTIF_COLOR
	local NOTIF_BLUR = cfg.NOTIF_BLUR

	local MAX_NOTIFS = 4

	local ICONS = {
		key = { Images.KEY, 18 },
		submit = { Images.SUBMIT, 18 },
		link = { Images.LINK, 18 },
		discord = { Images.DISCORD, 18 },
		close = { Images.CLOSE_ICON, 14 },
		moon = { Images.MOON_ICON, 14 },
	}

	local function kindColor(kind)
		if kind == "success" then
			return C.success
		elseif kind == "warn" then
			return C.warn
		elseif kind == "error" then
			return C.error
		end
		return C.accent
	end

	local notifHolder = make("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -8),
		Size = UDim2.new(0, NOTIF_W, 1, -16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, root)
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, notifHolder)

	local notifCount = 0
	local activeNotifs = {}

	local Blur = { effect = nil, users = 0 }

	function Blur.to(size, time)
		if NOTIF_BLUR <= 0 then
			return
		end
		if not Blur.effect then
			local ok, effect = pcall(function()
				local e = Instance.new("BlurEffect")
				e.Name = "AirflowBlur"
				e.Size = 0
				e.Parent = Lighting
				return e
			end)
			if not ok then
				return
			end
			Blur.effect = effect
		end
		tween(Blur.effect, time, { Size = size })
	end

	function Blur.acquire()
		Blur.users += 1
		Blur.to(NOTIF_BLUR, 0.35)
	end

	function Blur.release()
		Blur.users = math.max(Blur.users - 1, 0)
		if Blur.users == 0 and Blur.effect then
			Blur.to(0, 0.5)
		end
	end

	root.Destroying:Connect(function()
		if Blur.effect then
			Blur.effect:Destroy()
			Blur.effect = nil
		end
	end)

	local function notify(title, message, kind, iconKey, duration)
		kind = kind or "info"
		duration = duration or 3.5
		local color = kindColor(kind)
		local spec = ICONS[iconKey] or (kind == "error" and ICONS.close or ICONS.key)

		notifCount += 1
		Blur.acquire()

		local wrapper = make("Frame", {
			LayoutOrder = notifCount,
			Size = UDim2.new(0, NOTIF_W, 0, NOTIF_H + 8),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, notifHolder)

		local toast = make("TextButton", {
			Position = UDim2.new(0, 40, 0, 0),
			Size = UDim2.new(0, NOTIF_W, 0, NOTIF_H),
			BackgroundColor3 = C[NOTIF_COLOR],
			BackgroundTransparency = NOTIF_TRANSPARENCY,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			ClipsDescendants = true,
			Text = "",
		}, wrapper)
		round(toast, 10, C.stroke)
		toast.UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		toast.UIStroke.Transparency = 0.35

		local badge = frame(toast, 16, (NOTIF_H - 36) / 2, 36, 36, color, 0.86)
		round(badge, 18, color)
		badge.UIStroke.Transparency = 0.6

		local badgeIcon = make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, spec[2], 0, spec[2]),
			BackgroundTransparency = 1,
			Image = spec[1],
			ImageColor3 = ctx.tintIcons and color or Color3.fromRGB(255, 255, 255),
		}, badge)
		local iconScale = make("UIScale", { Scale = 0.5 }, badgeIcon)

		local titleLabel = text(toast, title, 64, 15, NOTIF_W - 78, 18, 13, C.text)
		titleLabel.FontFace = FONT_BOLD
		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		local msgLabel = text(toast, message, 64, 35, NOTIF_W - 78, 18, 12, C.muted)
		msgLabel.TextTruncate = Enum.TextTruncate.AtEnd

		local items = prep(toast)
		fade(items, 0)

		local handle = {}
		local dismissed = false
		function handle.dismiss()
			if dismissed then
				return
			end
			dismissed = true
			Blur.release()
			local idx = table.find(activeNotifs, handle)
			if idx then
				table.remove(activeNotifs, idx)
			end
			fade(items, 0, 0.25)
			tween(toast, 0.3, { Position = UDim2.new(0, 40, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.28, function()
				tween(wrapper, 0.2, { Size = UDim2.new(0, NOTIF_W, 0, 0) })
				task.delay(0.22, function()
					wrapper:Destroy()
				end)
			end)
		end

		toast.MouseButton1Click:Connect(handle.dismiss)

		fade(items, 1, 0.3)
		tween(toast, 0.45, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint)
		tween(iconScale, 0.55, { Scale = 1 }, Enum.EasingStyle.Back)

		local hovering, hoverSince = false, 0
		toast.MouseEnter:Connect(function()
			if dismissed then
				return
			end
			hovering = true
			hoverSince = os.clock()
			tween(toast, 0.15, { BackgroundColor3 = NOTIF_COLOR == "bg" and C.card or C.btn2 })
		end)
		toast.MouseLeave:Connect(function()
			if dismissed then
				return
			end
			hovering = false
			tween(toast, 0.15, { BackgroundColor3 = C[NOTIF_COLOR] })
		end)

		task.spawn(function()
			local remaining = duration
			local last = os.clock()
			while not dismissed do
				task.wait(0.05)
				local now = os.clock()
				if not (hovering and now - hoverSince < 8) then
					remaining -= now - last
				end
				last = now
				if remaining <= 0 then
					handle.dismiss()
					break
				end
			end
		end)

		table.insert(activeNotifs, handle)
		while #activeNotifs > MAX_NOTIFS do
			activeNotifs[1].dismiss()
		end

		return handle
	end

	local function dismissAll()
		for i = #activeNotifs, 1, -1 do
			activeNotifs[i].dismiss()
		end
	end

	return {
		notify = notify,
		dismissAll = dismissAll,
		blur = Blur,
	}
end

return Notification
