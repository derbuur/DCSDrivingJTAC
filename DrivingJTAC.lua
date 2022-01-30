-- Driving JTAC by buur

-- trigger.action.markToCoalition( 1 , "T00" , {0,0,0} , 2 , true) -- dummy target, will not shown in target list
-- trigger.action.markToCoalition( 2 , "T00" , {0,0,0} , 0 , true) -- dummy target, will not shown in target list
-- trigger.action.markToCoalition( 3 , "T00" , {0,0,0} , 1 , true) -- dummy target, will not shown in target list


function s(table)
local Result = routines.utils.oneLineSerialize(table)
MESSAGE:New(Result,10):ToAll()
env.info(Result)
return Result
end

 Cardinals = function(angle)
      if     angle <= 22.5  and angle >= 0 then return "N"
	  elseif angle <= 360   and angle > 337.5 then return "N"
	  elseif angle <= 67.5  and angle > 22.5  then return "NE"
	  elseif angle <= 112.5 and angle > 67.5  then return "E"
	  elseif angle <= 157.5 and angle > 112.5 then return "SE"
	  elseif angle <= 202.5 and angle > 157.5 then return "S"
	  elseif angle <= 247.5 and angle > 202.5 then return "SW"
	  elseif angle <= 292.5 and angle > 247.5 then return "W"
	  elseif angle <= 337.5 and angle > 292.5 then return "NW"
	  else
	  env.info("angle higher 360")
	  end
	end

active_requests = {}
DrivingJTACShowRequest = {}


	local BullsCoordinateBlue = COORDINATE:NewFromVec3( coalition.getMainRefPoint( 2 ) )
	local BullsCoordinateRed = COORDINATE:NewFromVec3( coalition.getMainRefPoint( 1 ) )
	local BullsCoordinateGreen = COORDINATE:NewFromVec3( coalition.getMainRefPoint( 0 ) )

	--local Coordinate=AIRBASE:FindByName("Batumi"):GetCoordinate() -- dummy coordinate for AV-8B ATHS
	MARKER:New(BullsCoordinateBlue, "T00"):ToCoalition(2) -- dummy Zone for AV-8B ATHS
	MARKER:New(BullsCoordinateRed, "T00"):ToCoalition(1)
	MARKER:New(BullsCoordinateGreen, "T00"):ToCoalition(0)
	
--s(Coordinate)
--env.info("coordinate Batumi "..Coordinate) 


--local MenuDrivingJTACRed = MENU_COALITION:New( coalition.side.RED, "Driving JTAC" )
--local MenuDrivingJTACBlue = MENU_COALITION:New( coalition.side.BLUE, "Driving JTAC" )
local MenuDrivingJTAC = MENU_MISSION:New( "Driving JTAC" )


drivingJTAC = function(JTAC,RecceZone)--,ATHS_Marker)
	--aths_marker = ATHS_Marker or false

	local drivingJTAC=ARMYGROUP:New(JTAC)
	drivingJTAC:Activate()
	drivingJTAC:SetDetection(true) -- Switch detection on.

	local AllZones=SET_ZONE:New():FilterOnce()
	drivingJTAC:SetCheckZones(AllZones)
	local zoneWP1=ZONE:New(RecceZone)
	local wp1=drivingJTAC:AddWaypoint(zoneWP1:GetCoordinate(), 30, nil, ENUMS.Formation.Vehicle.OffRoad)




	function drivingJTAC:OnAfterDetectedGroupNew(From, Event, To, Group) --- Function called whenever a group has been detected for the first time.
			 local ThreatLevels = {
			"Unarmed", 
			"Infantry", 
			"Old Tanks & APCs", 
			"Tanks & IFVs without ATGM",   
			"Tanks & IFV with ATGM",
			"Modern Tanks",
			"AAA",
			"IR Guided SAMs",
			"SR SAMs",
			"MR SAMs",
			"LR SAMs"
		  }
	  local group=Group 
	  local unitsGroup = self:GetDetectedUnits():GetUnitTypesText()--GetTypeNames()
		 local _,maxThreat = self:GetHighestThreat()
		 local currentthreattype = ThreatLevels[maxThreat+1]
		lasercode_table = { 1675, 1688 }
		
		lasercode = lasercode_table[ math.random( #lasercode_table ) ] 
		self:SetLaser(lasercode,true,false,nil)


	  wpDetection=self:AddWaypoint(self:GetCoordinate():Translate(200,self:GetHeading(),false,false), 30, self:GetWaypointIndexCurrent(), ENUMS.Formation.Vehicle.Vee,true) 
	  self:__FullStop(-1) -- FullStop work only on the actual waypoint. Here current possition
	  self:__LaserOn(60, group) --LaserOn(group)  -- Switch LASER on after 60 seconds.  __LaserOn(60, group)  __LaserOn(5, Target)

	local Coordinate = group:GetCoordinate()
	local mymarker=MARKER:New(Coordinate, "T00"):ToCoalition(self:GetCoalition()) --(coalition.side.BLUE)
	
	local mymarkerid = _MARKERID
	local request = mymarkerid + 1
    
	 
	local targetVelocity = self:GetDetectedUnits():GetFirst():GetVelocityKNOTS()
	local targetVelocityText = "failure"
	
	if targetVelocity < 1 then
		targetVelocityText = "static"
	else
		targetVelocityText = "moving"
	end
	
	local targetHeading = self:GetDetectedUnits():GetFirst():GetHeading()
	
	local targetHeadingCardinals = "failure"
	if targetVelocity < 1  then
		targetHeadingCardinals = ""
	else
		targetHeadingCardinals = Cardinals(targetHeading)
	end
	--local targetVelocityText = tostring(targetVelocity)
	--local targetVelocityText = "dummy"
	local targetDescription = unitsGroup .. " - " .. targetVelocityText.." "..targetHeadingCardinals
--env.info("target Heading: " ..targetHeading)
	  local distance = math.floor((self:GetCoordinate():Get2DDistance(self:GetDetectedUnits():GetCoordinate()))*1.09361+0.5)
	  local angle = self:GetDetectedUnits():GetCoordinate():GetAngleDegrees(self:GetDetectedUnits():GetCoordinate():GetDirectionVec3(self:GetCoordinate()))
	  local angle = Cardinals(angle)
	  local text_NineLiner = string.format(" Message from %s \n Request Nr.: %d \n 4. ELEV %d \n 5. DESC %s \n     %s \n 6. %s \n     %s \n 7. Laser %d \n 8. FRND %s %s", self:GetName(), request ,(Group:GetHeight())*3.28084, currentthreattype, targetDescription, group:GetCoordinate():ToStringMGRS( nil ), group:GetCoordinate():ToStringLLDMS( nil ) , self:GetLaserCode(), distance, angle )
	  local text_JTAC = string.format("%s: has new request %d", self:GetName(), request)
	  MESSAGE:New(text_JTAC, 30):ToCoalition(self:GetCoalition())


	-- einfuegung text nur auf einer Seite zu sehen
	   local function showNineLiner(group)
			MESSAGE:New(text_NineLiner, 60):ToGroup(group,20)
		end

	  env.info("self:GetCoalition: " ..self:GetCoalition())
	  
	  local coalitionNumber = self:GetCoalition()
	  
	  local coaltitionName = ""
	
	  if coalitionNumber == 0 then
		coaltitionName = "neutral" -- not sure if this is the right word
	  elseif coalitionNumber == 1 then
		coaltitionName = "red"
	  else 
		coaltitionName = "blue"
	  end
	 env.info("coaltitionName: " ..coaltitionName)
	  
	  
	
	  local menuHandle = {}
	  local Clients = SET_CLIENT:New():FilterCoalitions(coaltitionName):FilterStart()
	  
		Clients:ForEachClient(function (MenuClient)
			if MenuClient:GetGroup() ~= nil then
				local group = MenuClient:GetGroup()
				local groupName = group:GetName()

				menuHandle[group] = MENU_COALITION_COMMAND:New( self:GetCoalition(), "Show Request "..request , MenuDrivingJTAC, showNineLiner, group)


			end
		end)
		
	DrivingJTACShowRequest = {[request] = {menuHandle}}
	-- einfuegung ende
		
	  --DrivingJTACShowRequest = MENU_COALITION_COMMAND:New( self:GetCoalition(), "Show Request "..request , MenuDrivingJTACBlue, showNineLiner) --ShowStatus, "Status of planes is ok!", "Message to Red Coalition" )
	  
	  active_requests[self] = {["request"] = request, ["mymarker"] = mymarker , ["ShowRequest"] = DrivingJTACShowRequest}
	  
	  return active_requests

	end

	function drivingJTAC:OnAfterPassingWaypoint(From, Event, To, Waypoint)
	  local wp2_JTAC_17=drivingJTAC:AddWaypoint(zoneWP1:GetRandomCoordinate(), 30, nil, ENUMS.Formation.Vehicle.OffRoad)
	end


	--- Function called whenever a dected group could not be detected anymore.
	function drivingJTAC:OnAfterDetectedGroupLost(From, Event, To, Group)
	  local unitsGroup = self:GetDetectedUnits():GetTypeNames()  
	  local text=string.format("%s: LOST Request %d, abort", self:GetName(), active_requests[self]["request"])
	  MESSAGE:New(text, 30):ToCoalition(self:GetCoalition())
	  --env.info(text)
		self:LaserOff()
		self:RemoveWaypointByID(wpDetection.uid)
		self:Cruise()
		
		active_requests[self]["mymarker"]:Remove()
		request = active_requests[self]["request"]

		local importantTable = {}
		importantTable = active_requests[self]["ShowRequest"]
		for index, value in pairs(importantTable[request]) do
			value:Remove()
		end
		
		
		
	end

	--- Function called when the group enteres a zone.
	function drivingJTAC:OnAfterEnterZone(From, Event, To, Zone)
	 
	  local text=string.format("%s entered zone %s, start recce", self:GetName(), Zone:GetName())
	  MESSAGE:New(text, 30):ToCoalition(self:GetCoalition()) --:ToAll()
	  env.info(text)

	end

	--- Function called when the LASER is switched on.
	function drivingJTAC:OnAfterLaserOn(From, Event, To, Target)
			local ThreatLevels = {
			"Unarmed", 
			"Infantry", 
			"Old Tanks & APCs", 
			"Tanks & IFVs without ATGM",   
			"Tanks & IFV with ATGM",
			"Modern Tanks",
			"AAA",
			"IR Guided SAMs",
			"SR SAMs",
			"MR SAMs",
			"LR SAMs"
		  }
		  
		 local whatsthat,maxThreat = self:GetHighestThreat()
		 local currentthreattype = ThreatLevels[maxThreat+1]


		
	  --currentthreatlevel = Target:GetThreatLevel()
	  --currentthreattype = ThreatLevels[currentthreatlevel+1]
	  local text=string.format("%s switching on LASER on Request %d (code %d) at target %s", self:GetName(),active_requests[self]["request"], self:GetLaserCode(), currentthreattype) --Target:GetName())
	  MESSAGE:New(text, 30):ToCoalition(self:GetCoalition()) --:ToAll()
	  env.info(text)        
	end


end




drivingJTAC("BAYONET","Recce BAYONET")
drivingJTAC("Axeman","Recce Axeman")
drivingJTAC("Eyeball","Recce Eyeball")