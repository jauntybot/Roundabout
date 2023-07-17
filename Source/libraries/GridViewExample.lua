GridView = {}

class("GridView").extends()

local cards = {
    {body = "Increase your movement speed by 0.2."},
    {body = "Increase your attack strength by 2."},
    {body = "Increase your max HP by 20."},
    {body = "Restore 30 HP."}
}
print(cards[1].body)

local function shuffle(t)
    local tbl = {}
    for i = 1, #t do
      tbl[i] = t[i]
    end
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
  end

function GridView:init()
    self.grid = UI.gridview.new(96, 124)
    --self.grid.backgroundImage = Graphics.nineSlice.new('assets/images/ui/9slice_upgradeCard', 11, 11, 42, 42)
    self.grid:setNumberOfColumns(2)
    self.grid:setNumberOfRows(1)
    
    local image = Graphics.image.new(96 - 4, 124 - 4, Graphics.kColorWhite)
    local options = {
        imageTable = 'assets/images/ui/9slice_cardUpgrade',
        animated = false,
        size = { x = 96 - 4, y = 124 - 4},
        zIndex = 2
    }
    
    self.grid.cellSprites = {}
    self.grid.cards = {}
    local pulled = shuffle(cards)
    for i=1,self.grid:getNumberOfColumns() do
        self.grid.cards[i] = pulled[i]
        --self.grid.cellSprites[i] = BoutSprite(options)
    end

    self.grid:setSectionHeaderHeight(32)
    
    self.grid:setContentInset(1, 4, 1, 4)
    self.grid:setCellPadding(4, 4, 4, 4)
    self.grid.changeRowOnColumnWrap = false
    self.grid:selectPreviousRow(false)

    self.inputHandler = {
        upButtonDown = function()
            self.grid:selectPreviousRow(false);
        end,
        downButtonDown = function()
            self.grid:selectNextRow(false);
        end,
        leftButtonDown = function()
            self.grid:selectPreviousColumn(false);
        end,
        rightButtonDown = function()
            self.grid:selectNextColumn(false);
        end
    }
    
    function self.grid:drawCell(section, row, column, selected, x, y, width, height)
        Graphics.setColor(Graphics.kColorBlack)
        Graphics.drawRect(x, y, width, height)
        self.cellSprites[row]:moveTo(x, y)
        if selected then
            Graphics.fillRect(x + 2, y + 2, width - 4, height - 4)
        else

        end
        local title = ""..row.."-"..column
        local body = self.grid.cards[column].body
        
        if selected then
            Graphics.setImageDrawMode(Graphics.kDrawModeNXOR)
        else
            Graphics.setImageDrawMode(Graphics.kDrawModeCopy)
        end
        Graphics.setFont(Noble.Text.FONT_LARGE)
        Graphics.drawTextInRect(title, x, y+14, width, 20, nil, nil, kTextAlignment.center)
        Graphics.setFont(Noble.Text.FONT_SMALL)
        Graphics.drawTextInRect(body, x, y+40, width, height-20, nil, nil, kTextAlignment.center)
        Graphics.setImageDrawMode(Graphics.kDrawModeCopy)
    end

    function self.grid:drawSectionHeader(section, x, y, width, height)
        Graphics.setImageDrawMode(Graphics.kDrawModeNXOR)
        Graphics.drawText("*SECTION ".. section .. "*", x + 10, y + 8)
        Graphics.setImageDrawMode(Graphics.kDrawModeCopy)
    end
end

function GridView:update()
    self.grid:drawInRect(90, 0, 350, 240)
end

