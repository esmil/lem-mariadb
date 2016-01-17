#!/usr/bin/env lem
--
-- This file is part of lem-mariadb.
-- Copyright 2015 Kristian Nielsen
-- Copyright 2015 Emil Renner Berthing
--
-- lem-mariadb is free software: you can redistribute it and/or
-- modify it under the terms of the GNU General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
--
-- lem-mariadb is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with lem-mariadb. If not, see <http://www.gnu.org/licenses/>.
--

package.path = '?.lua;'..package.path
package.cpath = '?.so;'..package.cpath

print("Entering " .. arg[0])

local prettyprint
do
	local write, format, tostring = io.write, string.format, tostring

	function prettyprint(t)
		if #t == 0 then
			write('<empty>\n')
			return
		end
		local widths, columns = {}, #t[1]
		for i = 1, columns do
			widths[i] = 0
		end

		for i = 1, #t do
			local row = t[i]
			for j = 1, columns do
				local value = row[j]
				if value and #value > widths[j] then
					widths[j] = #value
				end
			end
		end

		for i = 1, #widths do
			widths[i] = '%-' .. tostring(widths[i] + 1) .. 's';
		end

		for i = 1, #t do
			local row = t[i]
			for j = 1, columns do
				write(format(widths[j], row[j] or 'NULL'))
			end
			write('\n')
		end
	end
end

local mariadb = require 'lem.mariadb'

local db = assert(mariadb.connect('localhost', 'user', 'pass', 'test', 0, '/var/run/mysqld/mysqld.sock'))

assert(db:exec(
'DROP TABLE IF EXISTS mytable'))
assert(db:exec(
'CREATE TABLE mytable (id INT PRIMARY KEY AUTO_INCREMENT, name TEXT, foo INT)'))

assert(db:exec("INSERT INTO mytable (name, foo) VALUES ('alpha',1), ('beta',2), ('gamma',4), ('delta',8), ('epsilon',0)"))

local res = assert(db:exec('SELECT * FROM mytable WHERE id = 1'))
prettyprint(res)

local res1 = assert(db:exec([[
SELECT count(id) FROM mytable;
]]));
prettyprint(res1)

local s1 = assert(db:prepare('SELECT * FROM mytable WHERE id = ?'))
local res = assert(s1:run('3'))
prettyprint(res)

local s_insert = assert(db:prepare('INSERT INTO mytable(name, foo) VALUES (?, ?)'))
assert(s_insert:run('zeta', 32))
assert(s_insert:run('eta', nil))

local s_select = assert(db:prepare('SELECT id, name, foo FROM mytable WHERE foo IN (?, ?, ?)'))
local res2 = assert(s_select:run(32, 4, 9));
prettyprint(res2)

assert(db:exec('DROP TABLE mytable'))

print("Exiting " .. arg[0])

-- vim: syntax=lua ts=2 sw=2 noet:
