local Dialog = {}

function Dialog.new(ctx, callbacks)
	callbacks = callbacks or {}

	local C = ctx.C
	local make, frame, text, round = ctx.make, ctx.frame, ctx.text, ctx.round
	local tween, prep, fade = ctx.tween, ctx.prep, ctx.fade
	local state, Images, FONT_BOLD = ctx.state, ctx.images, ctx.FONT_BOLD

	local popup = make("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 10,
		Visible = false,
	}, ctx.canvas)

	local dim = make("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}, popup)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, dim)

	local popupCard = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 270, 0, 132),
		BackgroundColor3 = "card",
		BorderSizePixel = 0,
	}, popup)
	round(popupCard, 12, "stroke")

	local badge = frame(popupCard, 22, 20, 32, 32, "input", 0)
	round(badge, 16, "stroke")
	make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
		Image = Images.CLOSE_ICON,
		ImageColor3 = ctx.tintIcons and "accent" or Color3.fromRGB(255, 255, 255),
	}, badge)

	local popupTitle = text(popupCard, "Close Key System?", 66, 19, 182, 16, 14, "text")
	popupTitle.FontFace = FONT_BOLD
	local popupDesc = text(popupCard, "Are you sure you want to close the Key System?", 66, 38, 182, 30, 12, "muted")
	popupDesc.TextWrapped = true
	popupDesc.TextYAlignment = Enum.TextYAlignment.Top

	local function popupButton(label, x, primary)
		local btn = make("TextButton", {
			Position = UDim2.new(0, x, 0, 86),
			Size = UDim2.new(0, 109, 0, 32),
			BackgroundColor3 = primary and "submitBg" or "btn2",
			BackgroundTransparency = primary and 0.12 or 0,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = label,
			TextSize = 13,
			TextColor3 = primary and "submitText" or "text",
			FontFace = ctx.FONT,
		}, popupCard)
		if primary then
			round(btn, 8)
		else
			round(btn, 8, "stroke")
		end
		return btn
	end

	local cancelBtn = popupButton("Cancel", 22, false)
	local confirmBtn = popupButton("Close", 139, true)

	cancelBtn.MouseEnter:Connect(function()
		if state.closing or not state.popupOpen then
			return
		end
		tween(cancelBtn, 0.15, { BackgroundColor3 = C.btn2Hover })
	end)
	cancelBtn.MouseLeave:Connect(function()
		if state.closing or not state.popupOpen then
			return
		end
		tween(cancelBtn, 0.15, { BackgroundColor3 = C.btn2 })
	end)
	confirmBtn.MouseEnter:Connect(function()
		if state.closing or not state.popupOpen then
			return
		end
		tween(confirmBtn, 0.15, { BackgroundTransparency = 0 })
	end)
	confirmBtn.MouseLeave:Connect(function()
		if state.closing or not state.popupOpen then
			return
		end
		tween(confirmBtn, 0.15, { BackgroundTransparency = 0.12 })
	end)

	local popupItems = prep(popup)
	fade(popupItems, 0)

	local function show()
		if not state.ready or state.popupOpen or state.closing then
			return
		end
		state.popupOpen = true
		popup.Visible = true
		popupCard.Position = UDim2.new(0.5, 0, 0.5, 8)
		if callbacks.onOpen then
			callbacks.onOpen()
		end
		fade(popupItems, 1, 0.22)
		tween(popupCard, 0.35, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Quint)
	end

	local function hide()
		if not state.popupOpen or state.closing then
			return
		end
		state.popupOpen = false
		fade(popupItems, 0, 0.18)
		task.delay(0.2, function()
			if not state.popupOpen then
				popup.Visible = false
			end
		end)
	end

	cancelBtn.MouseButton1Click:Connect(hide)
	confirmBtn.MouseButton1Click:Connect(function()
		if callbacks.onConfirm then
			callbacks.onConfirm()
		end
	end)

	return {
		popup = popup,
		items = popupItems,
		show = show,
		hide = hide,
	}
end

return Dialog
