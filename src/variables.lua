return {
	-- Window Config
	Title = "Airflow",
	Description = "Key System",
	Logo = "", -- rbxassetid
	Theme = "Plant-Dark",
	Folder = "Ophyn-KSY",

	-- Buttons Config
	getkey = true,
	shopbt = "", 

	-- Intro Config
	startintro_size = 80, -- initial square size
	introloading_time = 3,
	squareintro_time = 1.2,

	-- Themes Config
	Changelogocolor = true,
	Changeiconscolor = true,

	-- Section Config
	discord_link = "",
	website_link = "",

	-- Script Execution
	Execute = "",
	Callback = function(key) -- roda depois do Execute; recebe a key digitada
		-- ...
	end,
}
