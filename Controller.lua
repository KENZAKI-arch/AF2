local Controller = {}

function Controller.init(Model, View)

    -- Fish toggle
    View.fishBtn.MouseButton1Click:Connect(function()
        Model.isFishing = not Model.isFishing
        View.setFish(Model.isFishing)
    end)

    -- Buy toggle
    View.buyBtn.MouseButton1Click:Connect(function()
        Model.autoBuyEnabled = not Model.autoBuyEnabled
        View.setBuy(Model.autoBuyEnabled)
        if Model.autoBuyEnabled then
            Model.checkBaitInventory()
        end
    end)

    -- Sell toggle
    View.sellBtn.MouseButton1Click:Connect(function()
        Model.autoSellEnabled = not Model.autoSellEnabled
        View.setSell(Model.autoSellEnabled)
        if Model.autoSellEnabled then
            Model.checkInventory()
        end
    end)

    -- Minimize
    local minimized = false
    View.minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        View.content.Visible = not minimized
        View.mainFrame.Size = minimized and UDim2.new(0, 260, 0, 40) or UDim2.new(0, 260, 0, 320)
        View.minBtn.Text = minimized and "+" or "-"
    end)

    -- Close
    View.closeBtn.MouseButton1Click:Connect(function()
        Model.isFishing = false
        Model.autoBuyEnabled = false
        Model.autoSellEnabled = false
        View.screenGui:Destroy()
    end)

    -- Status loop
    View.startStatusLoop(function()
        return {
            isFishing = Model.isFishing,
            autoBuyEnabled = Model.autoBuyEnabled,
            autoSellEnabled = Model.autoSellEnabled,
        }
    end)

    -- Start model loops
    Model.startLoops()

    -- Initial checks
    Model.checkBaitInventory()
    Model.checkInventory()
end

return Controller

111111111222222 tghe rtreutn1232122123321112323, testing gay aahhh gayaaass