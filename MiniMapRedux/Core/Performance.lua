-- Core/Performance.lua - Performance monitoring utilities

local MiniMapRedux = _G.MiniMapRedux
if not MiniMapRedux then return end

local Performance = {
    metrics = {},
    startTime = GetTime()
}

-- Record a performance metric
function Performance:RecordMetric(name, value)
    if not self.metrics[name] then
        self.metrics[name] = {
            samples = {},
            min = math.huge,
            max = -math.huge,
            sum = 0,
            count = 0
        }
    end
    
    local metric = self.metrics[name]
    table.insert(metric.samples, value)

    -- Keep only the last 50 samples (reduced from 100 to save memory)
    if #metric.samples > 50 then
        table.remove(metric.samples, 1)
    end
    
    metric.min = math.min(metric.min, value)
    metric.max = math.max(metric.max, value)
    metric.sum = metric.sum + value
    metric.count = metric.count + 1
end

-- Get average for a metric
function Performance:GetAverage(name)
    local metric = self.metrics[name]
    if not metric or metric.count == 0 then
        return 0
    end
    return metric.sum / metric.count
end

-- Get current metrics
function Performance:GetMetrics()
    local result = {}
    for name, metric in pairs(self.metrics) do
        result[name] = {
            average = self:GetAverage(name),
            min = metric.min,
            max = metric.max,
            count = metric.count
        }
    end
    return result
end

-- Reset all metrics
function Performance:Reset()
    table.wipe(self.metrics)
    self.startTime = GetTime()
end

-- Get uptime
function Performance:GetUptime()
    return GetTime() - self.startTime
end

-- Export the Performance module
MiniMapRedux.export("Performance", Performance)