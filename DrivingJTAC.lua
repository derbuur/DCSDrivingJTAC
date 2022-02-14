-- Driving JTAC by buur

-- Hinweise: UTILS.GetMarkID() UTILS._MarkID UTILS.RemoveMark(MarkID, Delay) 

UTILS.MetersToYard = function(meters)
  return meters*1.09361
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

dJTAC = {}
dJTAC.active_requests = {}
DrivingJTACShowRequest = {}
menu_command = {}
CMDMenues = {}

	local BullsCoordinateBlue = COORDINATE:NewFromVec3( coalition.getMainRefPoint( 2 ) ) -- dummy Zone same as bullseye
	local BullsCoordinateRed = COORDINATE:NewFromVec3( coalition.getMainRefPoint( 1 ) )
	local BullsCoordinateGreen = COORDINATE:NewFromVec3( coalition.getMainRefPoint( 0 ) )


	MARKER:New(BullsCoordinateBlue, "T00"):ToCoalition(2) -- dummy Zone for AV-8B ATHS
	MARKER:New(BullsCoordinateRed, "T00"):ToCoalition(1)
	MARKER:New(BullsCoordinateGreen, "T00"):ToCoalition(0)
	




local MenuDrivingJTAC = MENU_MISSION:New( "Driving JTAC" )


drivingJTAC = function(JTAC,RecceZone)
	

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
	

	local mymarkerid = UTILS.GetMarkID()

	local request = mymarkerid - 1
    
	 
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
	
	
	local targetDescription = unitsGroup .. " - " .. targetVelocityText.." "..targetHeadingCardinals

	  local distance = math.floor(UTILS.MetersToYard(self:GetCoordinate():Get2DDistance(self:GetDetectedUnits(1):GetCoordinate())))
	  local angle = self:GetDetectedUnits():GetCoordinate():GetAngleDegrees(self:GetDetectedUnits():GetCoordinate():GetDirectionVec3(self:GetCoordinate()))
	  local angle = Cardinals(angle)
	  local text_NineLiner = string.format(" Message from %s \n Request Nr.: %d \n 4. ELEV %d \n 5. DESC %s \n     %s \n 6. %s \n     %s \n 7. Laser %d \n 8. FRND %s %s", self:GetName(), request ,UTILS.MetersToFeet(Group:GetHeight()), currentthreattype, targetDescription, group:GetCoordinate():ToStringMGRS( nil ), group:GetCoordinate():ToStringLLDMS( nil ) , self:GetLaserCode(), distance, angle )
	  local text_JTAC = string.format("%s: has new request %d", self:GetName(), request)
	  MESSAGE:New(text_JTAC, 30):ToCoalition(self:GetCoalition())



	   local function showNineLiner(group)
			MESSAGE:New(text_NineLiner, 60):ToGroup(group,20)
		end

	  
	  local coalitionNumber = self:GetCoalition()
	  
	  local coaltitionName = ""
	
	  if coalitionNumber == 0 then
		coaltitionName = "neutral" -- not sure if this is the right word
	  elseif coalitionNumber == 1 then
		coaltitionName = "red"
	  else 
		coaltitionName = "blue"
	  end

	  
	  local clientList = {}
	  local clientListGroupNames = {}
	  
	  
	  local menuHandle = {}
	  local setgroupsForMessage = SET_GROUP:New():FilterCoalitions(coaltitionName):FilterCategories({"plane","helicopter"}):FilterStart()

	
	  setgroupsForMessage:ForEachGroupAlive(
		function( MooseGroup )
			local GroupsName = MooseGroup:GetName()
			local menuPerGroup = MENU_GROUP_COMMAND:New(MooseGroup,"Show Request "..request , MenuDrivingJTAC , showNineLiner , MooseGroup)
			CMDMenues[GroupsName] = menuPerGroup
		end
	  )

		
	DrivingJTACShowRequest[request] = CMDMenues
	dJTAC.active_requests[self] = {["request"] = request, ["mymarker"] = mymarker }--, ["ShowRequest"] = DrivingJTACShowRequest}
	  

	end

	function drivingJTAC:OnAfterPassingWaypoint(From, Event, To, Waypoint)
	  local wp2_JTAC_17=drivingJTAC:AddWaypoint(zoneWP1:GetRandomCoordinate(), 30, nil, ENUMS.Formation.Vehicle.OffRoad)
	end


	--- Function called whenever a dected group could not be detected anymore.
	function drivingJTAC:OnAfterDetectedGroupLost(From, Event, To, Group)
	  local unitsGroup = self:GetDetectedUnits():GetTypeNames()  
	  local text=string.format("%s: LOST Request %d, abort", self:GetName(), dJTAC.active_requests[self]["request"])
	  MESSAGE:New(text, 30):ToCoalition(self:GetCoalition())

		self:LaserOff()
		self:RemoveWaypointByID(wpDetection.uid)
		self:Cruise()
		
		
		dJTAC.active_requests[self]["mymarker"]:Remove()


		local request = dJTAC.active_requests[self]["request"]
		local menuTableToRemove = DrivingJTACShowRequest[request]--[1]--["Group"]-- die [1] sollte zwischen den {} lesen

		for index, value in pairs(menuTableToRemove) do
			value:Remove()
			value:Refresh()
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


		
	  local text=string.format("%s switching on LASER on Request %d (code %d) at target %s", self:GetName(),dJTAC.active_requests[self]["request"], self:GetLaserCode(), currentthreattype) --Target:GetName())
	  MESSAGE:New(text, 30):ToCoalition(self:GetCoalition()) --:ToAll()
	  env.info(text)        
	end


end




drivingJTAC("BAYONET","Recce BAYONET")
drivingJTAC("Axeman","Recce Axeman")
drivingJTAC("Eyeball","Recce Eyeball")