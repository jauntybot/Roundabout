
Expedition = {}
class('Expedition').extends()


function Expedition:init(exp)
    self.exp = {}
    self.currentMonster = nil
    self.index = 1
    
    if (exp == 1) then
        self.exp = { 'exp0101', 'exp0102', 'exp0103', 'exp0104', 'exp0105' }
        self.currentMonster = self.exp[1]
        
    elseif (exp == 2) then
        self.exp = { 'exp0201', 'exp0202', 'exp0203', 'exp0204', 'exp0205' }
        self.currentMonster = self.exp[1]

    elseif (exp == 3) then
         self.exp = { 'exp0301', 'exp0302', 'exp0303', 'exp0304', 'exp0305','exp0306' ,'exp0307','exp0308','exp0309'}
        self.currentMonster = self.exp[1]
        
    end
end

function Expedition:NextMonster()
    local monster = self.currentMonster
    self.index = self.index + 1
    if self.index > GetTableLength(self.exp) then
        self.index = 1
    end
    self.currentMonster = self.exp[self.index]
    return monster
end