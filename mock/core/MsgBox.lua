
-- function Actor:flushMsgBox()
-- 	local box=self.msgbox
-- 	self.msgbox={}	
-- end

-- function Actor:clearMsgBox()
-- 	self.msgbox={}
-- end

-- function Actor:pollMsg()
-- 	local m=remove(self.msgbox,1)
-- 	if m then return m[1],m[2],m[3] end
-- 	return nil
-- end

-- function Actor:waitMsg(...)
-- 	while true do
-- 		local msg,data=self:pollFindMsg(...)
-- 		if msg then return msg,data end
-- 		yield()
-- 	end
-- end

-- function Actor:peekMsg()
-- 	local m=self.msgbox[1]
-- 	if m then return m[1],m[2],m[3] end
-- 	return nil
-- end

-- function Actor:pollFindMsg(...)
-- 	local msgbox=self.msgbox
-- 	if not msgbox[1] then return nil end
-- 	local count=select('#',...)

-- 	if count==1 then --single version
-- 		local mm=select(1,...)
-- 		while true do
-- 			local m=remove(msgbox,1)
-- 			if m then
-- 				if m[1]==mm then return m[1],m[2],m[3] end
-- 			else
-- 				break
-- 			end
-- 		end

-- 	else
-- 		while true do
-- 			local m=remove(msgbox,1)
-- 			if m then
-- 				local msg=m[1]
-- 				for i=1, count do
-- 					if msg == select(i,...) then
-- 						return m[1],m[2],m[3]
-- 					end
-- 				end
-- 			else
-- 				break
-- 			end

-- 		end
-- 	end

-- 	return nil
-- end
