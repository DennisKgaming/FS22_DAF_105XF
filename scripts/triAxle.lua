--
-- triAxle
-- Specialization for Tri Axle Trucks
--
-- @author looseterror
-- @date  08/18/11
--
-- Copyright (C)
-- @date 9/18/11

triAxle = {};
function triAxle.prerequisitesPresent(specializations)
    return true;
end;
function triAxle:load(savegame)
    self.triAxleState = SpecializationUtil.callSpecializationsFunction("triAxleState");
    local triAxleNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.triAxle#index"));
    if triAxleNode ~= nil then
        self.triAxle = {};
        self.triAxle.node = triAxleNode;
        local x,y,z = Utils.getVectorFromString(getXMLString(self.xmlFile, "vehicle.triAxle#minTrans"));
        self.triAxle.minTrans = {};
        self.triAxle.minTrans[1] = Utils.getNoNil(x, 0);
        self.triAxle.minTrans[2] = Utils.getNoNil(y, 0);
        self.triAxle.minTrans[3] = Utils.getNoNil(z, 0);
        local x,y,z = Utils.getVectorFromString(getXMLString(self.xmlFile, "vehicle.triAxle#maxTrans"));
        self.triAxle.maxTrans = {};
        self.triAxle.maxTrans[1] = Utils.getNoNil(x, 0);
        self.triAxle.maxTrans[2] = Utils.getNoNil(y, 0);
        self.triAxle.maxTrans[3] = Utils.getNoNil(z, 0);
        self.triAxle.transTime = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.triAxle#transTime"), 2)*1000;
        self.triAxle.touchTransLimit = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.triAxle#touchTransLimit"), 10);
    end;
    self.simulatedWheel1 = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.simulatedWheel1#index"));
    self.simulatedWheel2 = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.simulatedWheel2#index"));
    self.triAxleLowered = false;
    
    self.triAxleSoundEnabled = false;
-- Configure TriAxle Sound
    local triAxleSound = getXMLString(self.xmlFile, "vehicle.triAxleSound#file");
    if triAxleSound ~= nil and triAxleSound ~= "" then
        triAxleSound = Utils.getFilename(triAxleSound, self.baseDirectory);
        self.triAxleSound = createSample("triAxleSound");
        loadSample(self.triAxleSound, triAxleSound, false);
        self.triAxleSoundPitchOffset = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.triAxleSound#pitchOffset"), 0);
        self.triAxleSoundVolume = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.triAxleSound#volume"), 0.5);
        self.triAxleSoundDuration = getSampleDuration(self.triAxleSound);

    end;
    
end;
function triAxle:delete()
    if self.triAxleSoundEnabled  then
        stopSample(self.triAxleSound);
        self.triAxleSoundEnabled = false;
    end;
end;
function triAxle:update(dt)
    if self:getIsActiveForInput() then
        if InputBinding.hasEvent(InputBinding.triAxle) then
            self.triAxleLowered = not self.triAxleLowered;
            self:triAxleState(self.triAxleLowered);
            playSample(self.triAxleSound, 1, self.triAxleSoundVolume, (self.triAxleSoundDuration - self.triAxle.transTime));
            setSamplePitch(self.triAxleSound, self.triAxleSoundPitchOffset);
        end;
    end;

    if self.triAxle ~= nil then
        local x,y,z = getTranslation(self.triAxle.node);
        local trans = {x,y,z};
        local newTrans = Utils.getMovedLimitedValues(trans, self.triAxle.maxTrans, self.triAxle.minTrans, 3, self.triAxle.transTime, dt, self.triAxleLowered);
        setTranslation(self.triAxle.node, unpack(newTrans));
    end;
    if self.triAxleLowered then
        if self.simulatedWheel1 ~= nil then
            local x,y,z = getRotation(self.wheels[3].repr);
            setRotation(self.simulatedWheel1, x, y, z);
        end;
        if self.simulatedWheel2 ~= nil then
            local x,y,z = getRotation(self.wheels[4].repr);
            setRotation(self.simulatedWheel2, x, y, z);
        end;
    end;
end;
function triAxle:draw()
    if self.isEntered then
        g_currentMission:addHelpButtonText(g_i18n:getText("triAxle_Down"),InputBinding.triAxle);
    else
        g_currentMission:addHelpButtonText(g_i18n:getText("triAxle_Up"),InputBinding.triAxle);
    end;
end;
function triAxle:mouseEvent(posX, posY, isDown, isUp, button)
end;
function triAxle:keyEvent(unicode, sym, modifier, isDown)
end;
function triAxle:readStream(streamId, connection)
    self.triAxleLowered = streamReadBool(streamId);
end;
function triAxle:writeStream(streamId, connection)
    streamWriteBool(streamId, self.triAxleLowered);
end;
function triAxle:triAxleState(triAxleState, noEventSend)
    triAxleEvent.sendEvent(self, triAxleState, noEventSend);
    if triAxleState then
        self.triAxleLowered = true;
    else
        self.triAxleLowered = false;
    end;
end;
triAxleEvent = {};
triAxleEvent_mt = Class(triAxleEvent, Event);
InitEventClass(triAxleEvent, "triAxleEvent");
function triAxleEvent:emptyNew()
    local self = Event:new(triAxleEvent_mt);
    self.className="triAxleEvent";
    return self;
end;
function triAxleEvent:new(vehicle, triAxleLowered)
    local self = triAxleEvent:emptyNew()
    self.vehicle = vehicle;
    self.triAxleLowered = triAxleLowered;
    return self;
end;
function triAxleEvent:readStream(streamId, connection)
    local id = streamReadInt32(streamId);
    self.triAxleLowered = streamReadBool(streamId);
    self.vehicle = networkGetObject(id);
    self:run(connection);
end;
function triAxleEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));
    streamWriteBool(streamId, self.triAxleLowered);
end;
function triAxleEvent:run(connection)
    self.vehicle:triAxleState(self.triAxleLowered, true);
    if not connection:getIsServer() then
        g_server:broadcastEvent(triAxleEvent:new(self.vehicle, self.triAxleLowered), nil, connection, self.vehicle);
    end;
end;
function triAxleEvent.sendEvent(vehicle, triAxleLowered, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(triAxleEvent:new(vehicle, triAxleLowered), nil, nil, vehicle);
        else
            g_client:getServerConnection():sendEvent(triAxleEvent:new(vehicle, triAxleLowered));
        end;
    end;
end;