-- Driving JTAC by buur

-- ToDo
-- JTAC has problems when he detect two enemys at the same time
-- Map marker for AV-8B ATHS should be optional - made problems because I need the markerid for the requestnumber.
-- Switching laser target should be anounced and a litte bit more time between the switch
-- Script stopp working when JTAC is destroyed
-- Optional Smoke
-- Message shows only to some groups
-- There is an error when a own unit enters the detection range?
-- ARMYGROUP hat wohl probleme mit Bunkern ... bekomme fehlermeldung wenn einer drinn ist.
-- check the enviroment on which the target is... flied, wood etc.. only possible to check if road or not. So this point is not so important.
-- check if two JTACs have the same target
-- make the target coordinats a little bit fuzzy
-- check for invisible mark points
-- make a general function for the first created mark point

-- Hm, mit SET_CLIENT:New() eine Liste aller Clienten erstellen
-- dann mit GetSet() das Set auslesen

function s(table)
local Result = routines.utils.oneLineSerialize(table)
MESSAGE:New(Result,10):ToAll()
env.info(Result)
return Result
end

 Cardinals =function(angle)
      if     angle <= 22.5  and angle >= 0 then return "N"
	  elseif angle <= 360   and angle > 337.5 then return "N"
	  elseif angle <= 67.5  and angle > 22.5  then return "NW"
	  elseif angle <= 112.5 and angle > 67.5  then return "W"
	  elseif angle <= 157.5 and angle > 112.5 then return "SW"
	  elseif angle <= 202.5 and angle > 157.5 then return "S"
	  elseif angle <= 247.5 and angle > 202.5 then return "SE"
	  elseif angle <= 292.5 and angle > 247.5 then return "E"
	  elseif angle <= 337.5 and angle > 292.5 then return "NE"
	  else
	  env.info("angle higher 360")
	  end
	end

active_requests = {}
local MenuDrivingJTACRed = MENU_COALITION:New( coalition.side.RED, "Driving JTAC" )
local MenuDrivingJTACBlue = MENU_COALITION:New( coalition.side.BLUE, "Driving JTAC" )

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

	  local distance = math.floor((self:GetCoordinate():Get2DDistance(self:GetDetectedUnits():GetCoordinate()))*1.09361+0.5)
	  local angle = self:GetDetectedUnits():GetCoordinate():GetAngleDegrees(self:GetDetectedUnits():GetCoordinate():GetDirectionVec3(self:GetCoordinate()))
	  local angle = Cardinals(angle)
	  local text_NineLiner = string.format(" Message from %s \n Request Nr.: %d \n 4. ELEV %d \n 5. DESC %s \n    %s \n 6. %s \n     %s \n 7. Laser %d \n 8. FRND %s %s", self:GetName(), request ,(Group:GetHeight())*3.28084, currentthreattype, targetDescription, group:GetCoordinate():ToStringMGRS( nil ), group:GetCoordinate():ToStringLLDMS( nil ) , self:GetLaserCode(), distance, angle )
	  local text_JTAC = string.format("%s: has new request %d", self:GetName(), request)
	  MESSAGE:New(text_JTAC, 30):ToCoalition(self:GetCoalition()) --:ToAll()
	
	   local function showNineLiner()
			MESSAGE:New(text_NineLiner, 30):ToCoalition(self:GetCoalition())
		end

	  
	  
	  
	
	  DrivingJTACShowRequest = MENU_COALITION_COMMAND:New( self:GetCoalition(), "Show Request "..request , MenuDrivingJTACBlue, showNineLiner) --ShowStatus, "Status of planes is ok!", "Message to Red Coalition" )
	  
	  active_requests[self] = {["request"] = request, ["mymarker"] = mymarker , ["ShowRequest"] = DrivingJTACShowRequest}
	  
	  return active_requests

	end

	function drivingJTAC:OnAfterPassingWaypoint(From, Event, To, Waypoint)
	  local wp2_JTAC_17=drivingJTAC:AddWaypoint(zoneWP1:GetRandomCoordinate(), 30, nil, ENUMS.Formation.Vehicle.OffRoad)
	end


	--- Function called whenever a dected group could not be detected anymore.
	function drivingJTAC:OnAfterDetectedGroupLost(From, Event, To, Group)
	  local group=Group
	  local unitsGroup = self:GetDetectedUnits():GetTypeNames()
	  
		
	  
	  local text=string.format("%s: LOST Request %d, abort", self:GetName(), active_requests[self]["request"])--active_requests.self.request)
	  MESSAGE:New(text, 30):ToCoalition(self:GetCoalition()) --:ToAll()
	  env.info(text)
		self:LaserOff()
		self:RemoveWaypointByID(wpDetection.uid)
		self:Cruise()
		
		active_requests[self]["mymarker"]:Remove()
		active_requests[self]["ShowRequest"]:Remove()
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


		 s(whatsthat)
	  --currentthreatlevel = Target:GetThreatLevel()
	  --currentthreattype = ThreatLevels[currentthreatlevel+1]
	  local text=string.format("%s switching on LASER on Request %d (code %d) at target %s", self:GetName(),active_requests[self]["request"], self:GetLaserCode(), currentthreattype) --Target:GetName())
	  MESSAGE:New(text, 30):ToCoalition(self:GetCoalition()) --:ToAll()
	  env.info(text)        
	end


end


local Coordinate=AIRBASE:FindByName("Batumi"):GetCoordinate() -- dummy coordinate for AV-8B ATHS
local mymarker=MARKER:New(Coordinate, "T00"):ToCoalition(2) -- dummy Zone for AV-8B ATHS

drivingJTAC("BAYONET","Recce BAYONET")
drivingJTAC("Axeman","Recce Axeman")
drivingJTAC("Eyeball","Recce Eyeball")
