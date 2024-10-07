local M = {}

function M.mergeKvTable(t1, t2)
	if not t2 then
		return t1
	end

	for key, value in pairs(t2) do
		t1[key] = value
	end
	return t1
end

return M
