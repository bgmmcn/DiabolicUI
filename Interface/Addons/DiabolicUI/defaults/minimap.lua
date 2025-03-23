local Addon, Engine = ...

Engine:NewConfig("Minimap", {
	useGameTime = false, 
	use24hrClock = true,
	useSmallerMap = false
})

Engine:NewConfig("WorldMap", {
	revealHidden = true
})
