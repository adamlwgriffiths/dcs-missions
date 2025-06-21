-- various functions that are missing from lua because ???
function string:removeprefix(p)
    return (self:sub(0, #p) == p) and self:sub(#p+1) or s
end
function string:endswith(suffix)
    return self:sub(-#suffix) == suffix
end
-- https://gist.github.com/justnom/9816256
function _tostring(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        -- Check the key type (ignore any numerical keys - assume its an array)
        if type(k) == "string" then
            result = result.."[\""..k.."\"]".."="
        end

        -- Check the value type
        if type(v) == "table" then
            result = result..table_to_string(v)
        elseif type(v) == "boolean" then
            result = result.._tostring(v)
        else
            result = result.."\""..v.."\""
        end
        result = result..","
    end
    -- Remove leading commas from the result
    if result ~= "" then
        result = result:sub(1, result:len()-1)
    end
    return result.."}"
end
function copytable(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = copytable(v)
		end
		copy[k] = v
	end
	return copy
end