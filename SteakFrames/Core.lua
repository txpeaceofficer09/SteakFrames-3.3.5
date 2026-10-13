Steak = Steak or {}
local Steak = Steak

Steak.Modules = Steak.Modules or {}
Steak.Frames = Steak.Frames or {}

local eventFrame = CreateFrame("Frame")

Steak.eventFrame = eventFrame

Steak.Initialized = false
Steak.Initializing = false
Steak.InitQueue = {}
Steak.InitIndex = 1
Steak.PendingGroupType = nil
Steak.GroupFramesCreated = false
Steak.RaidFramesCreated = false
Steak.PartyFramesCreated = false
Steak.InitBudget = 2 -- milliseconds per frame, between jobs only

function Steak:RegisterModule(module)
	assert(module, "Steak:RegisterModule() requires a module")

	for _, registered in ipairs(self.Modules) do
		if registered == module then
			return
		end
	end

	table.insert(self.Modules, module)
	module.Core = self
	module.Initialized = false

	if module.events then
		for index, event in pairs(module.events) do
			if type(index) == "number" and type(event) == "string" then
				self:RegisterEvent(event)
				print("Registering: " .. event)
			elseif type(index) == "string" then
				self:RegisterEvent(index)
				print("Registering: " .. index)
			end
		end
	end
end

function Steak:RegisterEvent(event)
	eventFrame:RegisterEvent(event)
end

function Steak:QueueInitialization(job)
	self.InitQueue[#self.InitQueue + 1] = job
end

function Steak:StartInitialization()
	if self.Initializing then
		return
	end

	-- The queue can be restarted after initial startup for lazily-created
	-- party/raid frames. InitIndex already points at the next queued job.
	if not self.InitQueue[self.InitIndex] then
		return
	end

	self.Initializing = true
end

function Steak:RunInitializationStep()
	if not self.Initializing then
		return
	end

	-- Secure unit frames must not be created or modified during combat.
	if InCombatLockdown() then
		return
	end

	local started = debugprofilestop()

	while self.InitQueue[self.InitIndex] do
		local job = self.InitQueue[self.InitIndex]
		self.InitIndex = self.InitIndex + 1
		job()

		-- Never interrupt a job, but yield between jobs once the budget is spent.
		if debugprofilestop() - started >= self.InitBudget then
			return
		end
	end

	self.Initializing = false
	self.Initialized = true
	self:UpdateLayouts()
end

function Steak:AppendModuleInitialization()
	for _, module in ipairs(self.Modules) do
		if not module.Initialized then
			local currentModule = module
			self:QueueInitialization(function()
				if currentModule.Initialize then
					currentModule:Initialize()
				end
				currentModule.Initialized = true
			end)
		end
	end
end

function Steak:OnEvent(event, ...)
	for _, module in ipairs(self.Modules) do
		if module.Initialized and module.OnEvent then
			if module.events then
				for key, value in pairs(module.events) do
					if value == event or key == event then
						module:OnEvent(event, ...)
						break
					end
				end
			end
		end
	end
end

function Steak:DispatchEvent(event, ...)
	self:OnEvent(event, ...)
end

function Steak:UpdateModules(elapsed)
	if self.Initializing or not self.Initialized then
		return
	end

	for _, module in ipairs(self.Modules) do
		if module.Initialized and module.OnUpdate then
			module:OnUpdate(elapsed)
		end
	end
end

function Steak:ForEachFrame(callback)
	for _, frame in ipairs(self.Frames) do
		callback(frame)
	end
end

function Steak:ForEachModule(callback)
	for _, module in ipairs(self.Modules) do
		callback(module)
	end
end

function Steak:UpdateFrame(frame)
	if not frame then return end

	for _, module in ipairs(self.Modules) do
		if module.UpdateFrame then
			module:UpdateFrame(frame)
		end
	end
end

function Steak:UpdateAll()
	for _, frame in ipairs(self.Frames) do
		if frame.unit and UnitExists(frame.unit) then
			self:UpdateFrame(frame)
		end
	end
end
