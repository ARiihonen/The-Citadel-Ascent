module(..., package.seeall)
debug.ReloadScripts.allowReload(...)


-- Sends an SQL query to C#. Results (including errors) are printed on console, if one exists.
function makeSQLQuery(queryStr, numberOfResultColumns)
	if not numberOfResultColumns then numberOfResultColumns = 1 end
	-- CSharpUI parser converts two backslashes to one (\\ => \, \\\\ => \\), so we must compensate
	local compensatedQuery, ns = queryStr:gsub("\\", "\\\\")
	externalUI:sendUICommand("makeSQLQuery(\"" .. compensatedQuery .. "\", \"" .. numberOfResultColumns .. "\")")
end

function queryResult(str)
	misc.util.printToConsole(str)
	sendQueryResultToUI(str)
end

function queryTablesResult(str)
	misc.util.printToConsole(str)
	sendQueryTablesResultToUI(str)
end

function sendQueryResultToUI(str)
	-- FIXME: this is not a proper parsing in any way. just a super quick hack.
	local strConverted = ""
	if (str == "") then
		strConverted = "(empty)\n{\n}\n"
	else
		strConverted = "___start___" .. str .. "___end___"
		strConverted = strConverted:gsub("},{", "\n")
		strConverted = strConverted:gsub("}\\n{", "\n}\ndatabaseTableRow\n{\n")
		strConverted = strConverted:gsub("___start___{", "databaseTableRow\n{\n")
		strConverted = strConverted:gsub("}\\n___end___", "\n}\n")
		-- encapsulate columns too:
		--strConverted = strConverted:gsub("},{", "\n}\ndatabaseTableColumn\n{\n")
		--strConverted = strConverted:gsub("}\\n{", "\n}\n}\ndatabaseTableRow\n{\ndatabaseTableColumn\n{\n")
		--strConverted = strConverted:gsub("___start___{", "databaseTableRow\n{\ndatabaseTableColumn\n{\n")
		--strConverted = strConverted:gsub("}\\n___end___", "\n}\n}\n")
	end
	if(externalUI) then
		externalUI:sendUICommand("sync(\"DatabaseExplorer\", \""..strConverted.."\")");
	end
end

function sendQueryTablesResultToUI(str)
	local strConverted = str
	strConverted = strConverted:gsub("{", "")
	strConverted = strConverted:gsub("}", "")
	strConverted = strConverted:gsub("\\n", "\n{\n}\n")
	if(externalUI) then
		externalUI:sendUICommand("sync(\"DatabaseExplorer\", \""..strConverted.."\")");
	end
end


function createSDBTable(name)
	makeSQLQuery("CREATE TABLE IF NOT EXISTS " .. name .. " ( Id VARCHAR(255) PRIMARY KEY, Data TEXT CHARACTER SET utf8, LastModified DATETIME DEFAULT 0 );")
	makeSQLQuery("DELETE FROM SimpleDBMetaTable WHERE DBName = '" .. name .. "';")
	makeSQLQuery("INSERT INTO SimpleDBMetaTable ( DBName ) VALUES ( '" .. name .. "' );")
	makeSQLQuery("DROP TRIGGER IF EXISTS lastModIUpdFor" .. name .. ";")
	makeSQLQuery("DROP TRIGGER IF EXISTS lastModUUpdFor" .. name .. ";")
	makeSQLQuery("DROP TRIGGER IF EXISTS lastModIMTUpdFor" .. name .. ";")
	makeSQLQuery("DROP TRIGGER IF EXISTS lastModUMTUpdFor" .. name .. ";")
	makeSQLQuery("DROP TRIGGER IF EXISTS lastModDMTUpdFor" .. name .. ";")
	makeSQLQuery("CREATE TRIGGER lastModIUpdFor" .. name .. " BEFORE INSERT ON " .. name .. " FOR EACH ROW SET NEW.LastModified = NOW();")
	makeSQLQuery("CREATE TRIGGER lastModUUpdFor" .. name .. " BEFORE UPDATE ON " .. name .. " FOR EACH ROW SET NEW.LastModified = NOW();")
	makeSQLQuery("CREATE TRIGGER lastModIMTUpdFor" .. name .. " AFTER INSERT ON " .. name .. 
			" FOR EACH ROW UPDATE SimpleDBMetaTable SET LastUpdate = NOW() + 0 WHERE DBName = '" .. name .. "';")
	makeSQLQuery("CREATE TRIGGER lastModUMTUpdFor" .. name .. " AFTER UPDATE ON " .. name .. 
			" FOR EACH ROW UPDATE SimpleDBMetaTable SET LastUpdate = NOW() + 0 WHERE DBName = '" .. name .. "';")
	makeSQLQuery("CREATE TRIGGER lastModDMTUpdFor" .. name .. " AFTER DELETE ON " .. name .. 
			" FOR EACH ROW UPDATE SimpleDBMetaTable SET LastDelete = NOW() + 0 WHERE DBName = '" .. name .. "';")
end


function dropSDBDatabase(name)
	makeSQLQuery("DROP TABLE IF EXISTS " .. name .. ";")
end


function listTables()
	makeSQLQuery("SHOW TABLES;")
end


function printSDBTable(name)
	makeSQLQuery("SELECT * FROM " .. name .. ";", 3)
end


function escapeForMySQL(str)
-- Not really sure which of these must be escaped
	local newStr
	local ns
	newStr, ns = str:gsub("\\", "\\\\")
	
	newStr, ns = newStr:gsub("'", "\\'")
--	newStr, ns = newStr:gsub("\"", "\\\"")
--	newStr, ns = newStr:gsub("\n", "\\n")
--	newStr, ns = newStr:gsub("\r", "\\r")
--	newStr, ns = newStr:gsub("\t", "\\t")
--	newStr, ns = newStr:gsub("%%", "\\%%")
--	newStr, ns = newStr:gsub("_", "\\_")
	return newStr
end


function copyFromFileToSQLDBFormat(dbFile, dbName)
	misc.util.printToConsole("Copying database from file " .. dbFile .. " to SQL database table " .. dbName)
	misc.util.printToConsole("Creating table if it doesn't exist")
	createSDBTable(dbName)
	local separator = '<-- DB_SEP -->'
	misc.util.printToConsole("Separator sequence is " .. separator)
	separator = '-- DB_SEP --'
	misc.util.printToConsole("Hacked separator sequence is " .. separator)
	for line in io.lines(dbFile) do
		misc.util.printToConsole("Accessing line " .. line)
		local b, e = string.find(line, separator)
		if b ~= nil and e ~= nil then
			local key = escapeForMySQL(string.sub(line, 1, b - 2))
			local data = escapeForMySQL(string.sub(line, e + 3))
			local queryString = "REPLACE INTO " .. dbName .. " (Id, Data) VALUES ( '" .. key .. "', '" .. data .. "');"
			misc.util.printToConsole("Query string: " .. queryString)
			makeSQLQuery(queryString)
		end
	end
end


function convertFileBasedDatabaseToSQLBased(dbFilePath, dbFilename)
	local dbName = dbFilename:gsub("Archive%.fbdb", "Arc%.fbdb")
	dbName = dbName:sub(0, -6)
	local fullPath = dbFilePath .. dbFilename
	local tmp
	dbName, tmp = dbName:gsub("%.", "_")
	misc.util.printToConsole("Dropping possible previous data for " .. dbName)
	dropSDBDatabase(dbName)
	copyFromFileToSQLDBFormat(fullPath, dbName)
end


function copyAllDatabases()
 	local fileNamePrefix = "\\\\NEW-SVN\\share\\editor_db\\"
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "test.fbe.fbdb")
	--convertFileBasedDatabaseToSQLBased(fileNamePrefix, "spooky_forest.fbe.fbdb")
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "QADBGlobal.fbdb")
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "tmp.fbe.fbdb")
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "pipes_mini_test.fbe.fbdb")
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "tutorial_v004_test.fbe.fbdb")
	--convertFileBasedDatabaseToSQLBased(fileNamePrefix, "tutorial_animations.fbe.fbdb")
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "animation_context_area.fbe.fbdb")
	--convertFileBasedDatabaseToSQLBased(fileNamePrefix, "QADBTEMP_temple_forest.fbe.fbdb")
	--convertFileBasedDatabaseToSQLBased(fileNamePrefix, "QADBTEMP_temple_forest.fbeArchive.fbdb")
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "maps.fbdb")
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "QADBminimal_test.fbe.fbdb")
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "QADBtest.fbe.fbdb")
	--convertFileBasedDatabaseToSQLBased(fileNamePrefix, "QADBtemple_forest.fbe.fbdb")
	--convertFileBasedDatabaseToSQLBased(fileNamePrefix, "QADBtutorial_v004.fbeArchive.fbdb")
	--convertFileBasedDatabaseToSQLBased(fileNamePrefix, "QADBtutorial_v004.fbe.fbdb")
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "ignored_tags.fbdb")
	convertFileBasedDatabaseToSQLBased(fileNamePrefix, "QADBGlobalArchive.fbdb")
end

