return {
	-- Window Config
	Title = "Ophyn",
	Description = "Key System",
	Logo = "rbxassetid://111673746737789", -- rbxassetid
	Theme = "Plant-Dark",
	Folder = "Ophyn-KSY",

	-- Buttons Config
	getkey = true,

	-- Intro Config
	Intro = "true", -- "false": fade-in on open, fade-out on close
	startintro_size = 80, -- initial square size
	squareintro_time = 1.2,
	squarecontorn = "true", -- "false": removes the outline around the intro square

	-- Themes Config
	Changelogocolor = true,
	Changeiconscolor = true,
	ChangeTheme = true, -- false: hides the moon (theme switch) icon

	-- Section Config
	discord_link = "",
	website_link = "",

	-- Cards ("true" / "false")
	Discord = "true",
	Website = "false",
	Informations = "true",

	-- Notification style
	NotifStyle = "1",

	-- Games
	SupportedGames = {},

	-- Script Execution
	Callback = function(key)
		-- your script here
	end,
}
