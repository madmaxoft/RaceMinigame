-- Info.lua

-- Implements the gPluginInfo standard plugin description




gPluginInfo =
{
	Name = "Race Minigame",
	Date = "2024-03-04",
	Description =
	[[
		A race minigame. A group of players takes part in races, with each race arena being a predefined
		area with a start and finish for each player. All competing players start at the same time
		and the fastest three are recorded for each run, with 3, 2 and 1 point being awarded respectively.
		The players accumulate their score and finally the point leaderboard is used to determine the winner.
	]],

	AdditionalInfo =
	{
		{
			Title = "Set up",
			Contents =
			[[
			TBD
			]],
		},
	},

	Commands =
	{
		["/rmg"] =
		{
			Subcommands =
			{
				start =
				{
					Handler = rmgStart,
					HelpString = "Starts the races",
					Permission = "rmg.start",
				},
				continue =
				{
					Handler = rmgContinue,
					HelpString = "Continues to the next race arena, awarding no points for players who currently haven't finished the current arena yet.",
					Permission = "rmg.continue",
				},
				finish =
				{
					Handler = rmgFinish,
					HelpString = "Finishes the races, displays player scores",
					Permission = "rmg.finish",
				},
				join =
				{
					Handler = rmgJoin,
					HelpString = "Join the races",
					Permission = "rmg.join",
				},
				alljoin =
				{
					Handler = rmgAllJoin,
					HelpString = "All players except you join the races",
					Permission = "rmg.alljoin",
				},
				leave =
				{
					Handler = rmgLeave,
					HelpString = "Leave the races",
					Permission = "rmg.leave",
				},

				arena =
				{
					Subcommands =
					{
						new =
						{
							Handler = rmgArenaNew,
							HelpString = "Creates a new arena, with entry at your current location",
							Permission = "rmg.arena.new",
							ParameterCombinations =
							{
								{
									Params = "ArenaName",
								},
							},
						},
						del =
						{
							Handler = rmgArenaDel,
							HelpString = "Removes the specified arena",
							Permission = "rmg.arena.del",
							ParameterCombinations =
							{
								{
									Params = "ArenaName",
								},
							},
						},
						list =
						{
							Handler = rmgArenaList,
							HelpString = "Lists all the available arenas",
							Permission = "rmg.arena.list",
						},
						["goto"] =
						{
							Handler = rmgArenaGoto,
							HelpString = "Teleports you to the entry of the specified arena",
							Permission = "rmg.arena.goto",
							ParameterCombinations =
							{
								{
									Params = "ArenaName",
								},
							},
						},
						newtrack =
						{
							Handler = rmgArenaNewTrack,
							HelpString = "Adds a new track to the specified arena, with the start at your position and finish area in current WorldEdit selection.",
							Permission = "rmg.arena.newtrack",
							ParameterCombinations =
							{
								{
									Params = "ArenaName",
								},
							},
						},
						deltrack =
						{
							Handler = rmgArenaDelTrack,
							HelpString = "Removes the specified track.",
							Permission = "rmg.arena.deltrack",
							ParameterCombinations =
							{
								{
									Params = "ArenaName TrackNum",
								},
							},
						},
						gototrack =
						{
							Handler = rmgArenaGotoTrack,
							HelpString = "Sets WorldEdit selection to the specified track's finish area, teleports you to track start.",
							Permission = "rmg.arena.seltrack",
							ParameterCombinations =
							{
								{
									Params = "ArenaName TrackNum",
								},
							},
						},
					},  -- Subcommands
				},  -- "/rmg arena" subcommand
			},  -- Subcommands
		},  -- "/rmg" command
	},  -- Commands

	ConsoleCommands =
	{
		rmg =
		{
			Subcommands =
			{
				alljoin =
				{
					Handler = conRmgAlljoin,
					HelpString = "All players join the race",
				},  -- "rmg alljoin" subcommand

				list =
				{
					Handler = conRmgList,
					HelpString = "Lists all the arenas",
				},  -- "rmg list" subcommand

				reload =
				{
					Handler = conRmgReload,
					HelpString = "Re-loads the RaceMinigame configuration",
				},  -- "rmg reload" subcommand

				save =
				{
					Handler = conRmgSave,
					HelpString = "Re-saves the current RaceMinigame configuration",
				},  -- "rmg save" subcommand
			},  -- Subcommands
		},  -- "rmg" command
	},  -- ConsoleCommands
}  -- gPluginInfo
