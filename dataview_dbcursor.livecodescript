script "DataView Database Cursor Controller Behavior" with behavior "DataView Behavior"
local sCursorId
local sCursorColumnsA
local sColumnCount
local sRecordCount
local sCurrentRow


/**
Summary: Set the database cursor that will feed the DataView.

Parameters:
pCursorId: A cursor id as returned by `revQueryDatabase()`.

Example:
put revQueryDatabase(tDatabaseId, "SELECT * FROM MyTable") into tCursorId
set the dvCursor of group "MyDataView" to tCursorId

Returns: nothing
*/
setProp dvCursor pCursorId
  local tColumnNames, i

  if pCursorId is empty then
    put 0 into sColumnCount
    put 0 into sRecordCount
    put 0 into sCursorId
    put empty into sCursorColumnsA
    put 0 into sCurrentRow
    ResetView
  else
    put pCursorId into sCursorId
    put revNumberOfRecords(sCursorId) into sRecordCount
    revMoveToFirstRecord sCursorId
    put 1 into sCurrentRow

    # Extract columns from cursor using index as it should be faster.
    put revDatabaseColumnNames(sCursorId) into tColumnNames
    repeat for each item tColumn in tColumnNames
      add 1 to i
      put tColumn into sCursorColumnsA[i]
    end repeat

    put i into sColumnCount

    lock screen
    ResetView
    RenderView
    unlock screen
  end if
end dvCursor


/**
Summary: Returns the internal cursor id.

Returns: Integer
*/
getProp dvCursor
  return sCursorId
end dvCursor


command DataForRow pRow, @rDataA, @rTemplateStyle
  local tColumn, tValue, tError

  _moveToRecord pRow
  _convertCurrentRowToArray rDataA

  put "default" into rTemplateStyle
end DataForRow


function NumberOfRows
  return sRecordCount
end NumberOfRows


function CacheKeyForRow pRow
  return pRow
end CacheKeyForRow


/**
Summary: Returns the `id` property of the selected row(s).

Description:
This property only returns a value if the cursor row has an `id` column.
If there is no `id` column then an empty value will be returned for each
selected row.

Returns: Comma-delimited list of row numbers.
*/
getProp dvHilitedIds
  local tRow, tRows, tIds

  put the dvHilitedRow of me into tRows

  if tRows is not empty then
    repeat for each item tRow in tRows
      _moveToRecord tRow
      put revDatabaseColumnNamed(sCursorId, "id") & "," after tIds
    end repeat
    delete the last char of tIds
  end if
  return tIds
end dvHilitedIds


getProp dvHilitedId
  return the dvHilitedIds of me
end dvHilitedId


/**
Summary: Sets the selected row based on the `id` property of a row(s).

Parameters:
pForceScroll: Passed along to `dvHilitedRow` in the DataView behavior.
pIds: The ids to select.

Description:
This property can only be set if the database cursor has an `id` column
that was selected as part of the cursor.

In order to find the rows associated with each the code will loop through
the database cursor. This may be slow for large data sets so test to make
sure the speed is acceptable.
*/
setProp dvHilitedIds[pForceScroll] pIds
  local tId, tRow, tRows

  repeat for each item tId in pIds
    put _rowOfId(tId) into tRow
    if tRow is not empty then
      put tRow & "," after tRows
    end if
  end repeat
  delete the last char of tRows

  set the dvHilitedRow[pForceScroll] of me to tRows
end dvHilitedIds


setProp dvHilitedId[pForceScroll] pIds
  set the dvHilitedIds[pForceScroll] of me to pIds
end dvHilitedId


/**
Summary: Returns the row data associated with `pRow`.

Parameters:
pRow: The target row.

Returns: Value
*/
getProp dvRowData[pRow]
  local tDataA

  _moveToRecord pRow
  _convertCurrentRowToArray tDataA
  return tDataA
end dvRowData


/**
Summary: Returns the row id associated with `pRow`.

Parameters:
pRow: The target row.

Description:
This property can only be set if the array created in `DataForRow`
has an `id` key.

Returns: Value
*/
getProp dvRowId[pRow]
  local tDataA

  _moveToRecord pRow
  _convertCurrentRowToArray tDataA, "id"

  return tDataA["id"]
end dvRowId


/**
Summary: Returns the row(s) associated with the provided ids.

Parameters:
pId: The `id` to search on.

Description:
If the id is not found then 0 is returned.

Returns: Integer
*/
getProp dvRowOfId[pId]
  return _rowOfId(pId)
end dvRowOfId


/**
Summary: Returns the row data associated with a specific `id`.

Parameters:
pId: The target `id`.

Description:
This property can only be set if the array created in `DataForRow`
has an `id` key.

Returns: Value
*/
getProp dvRowOfIdData[pId]
  local tRow

  put _rowOfId(pId) into tRow

  if tRow is not empty then
    local tDataA
    _moveToRecord tRow
    _convertCurrentRowToArray tDataA
  else
    return empty
  end if
end dvRowOfIdData


/**
Summary: Returns the data array of the currently selected row.

Description:
If a single row is selected then the array associated with that row
will be returned. If multiple rows are selected, then the result will
be a numerically indexed array of row data.

Returns: Array
*/
getProp dvHilitedData
  local tRows, tRowA

  put the dvHilitedRow of me into tRows

  if the number of items of tRows is 1 then
    _moveToRecord tRows
    _convertCurrentRowToArray tRowA
    return tRowA
  else
    local tDataA, tRow, i

    repeat for each item tRow in tRows
      add 1 to i
      _moveToRecord tRow
      _convertCurrentRowToArray tRowA
      put tRowA into tDataA[i]
    end repeat

    return tDataA
  end if
end dvHilitedData


/**
Summary: Returns a specific key in a row's array.

Parameters:
pRow: The target row.
pKey: The custom key.

Returns: Mixed
*/
function GetValueForKeyInRow pRow, pKey
  local tDataA

  _moveToRecord pRow
  _convertCurrentRowToArray tDataA, pKey

  return tDataA[pKey]
end GetValueForKeyInRow


/**
Summary: Redraws the row associated with the specified `id`.

Parameters:
pId: The target id.

Description:
Call this command after updating data in the DataView affects what is
displayed in the row.

Returns: nothing
*/
command RefreshRowOfId pId
  local tRow

  put _rowOfId(pId) into tRow

  if tRow is not empty then
    RenderRows tRow
  end if

  return empty
end RefreshRowOfId


private command _setHilitedIds pIds
  local tId, tRow, tRows

  repeat for each item tId in pIds
    put _rowOfId(tId) tRow
    if tRow is not empty then
      put tRow & "," after tRows
    end if
  end repeat
  delete the last char of tRows

  if tRows is not empty then
    set the dvHilitedRow of me to tRows
  end if

  return empty
end _setHilitedIds


/**
Summary: Returns the row associated with an id.

Parameters:
pId: The id to search on.

Description:
This function searchds for a row by moving through the open cursor.
It starts at the current record in the currsor and moves backwards
down to the first record. If the `id` is not found then it moves forward
from the original cursor position until it reaches the last record.

If the id is not found then 0 is returned.

Returns: Integer
*/
private function _rowOfId pId
  local i, tRows, tResult

  # start on current record and move backwards
  repeat with i = sCurrentRow down to 1
    if revDatabaseColumnNamed(sCursorId, "id") is pId then
      return i
    end if

    revMoveToPreviousRecord sCursorId
    if the result is true then
      put i-1 into sCurrentRow
    end if
  end repeat

  # Now work our way forward through the cursor
  if sCurrentRow < sRecordCount then
    # Note: revMoveToRecord is 0-based so don't add 1 to sCurrentRow when moving
    revMoveToRecord sCursorId, sCurrentRow
    if the result is true then
      add 1 to sCurrentRow

      repeat with i = sCurrentRow to sRecordCount
        if revDatabaseColumnNamed(sCursorId, "id") is pId then
          return i
        end if

        revMoveToNextRecord sCursorId
        if the result is true then
          put i+1 into sCurrentRow
        end if
      end repeat
    end if
  end if

  return 0
end _rowOfId


private command _moveToRecord pRow
  # revMoveToRecord is 0-based
  revMoveToRecord sCursorId, pRow-1
  put pRow into sCurrentRow
end _moveToRecord


private command _convertCurrentRowToArray @rDataA, pColumnFilter
  local tError, tValue

  set the wholematches to true

  repeat with i = 1 to sColumnCount
    if pColumnFilter is empty or sCursorColumnsA[i] is among the items of pColumnFilter then
      put revDatabaseColumnNumbered(sCursorId, i, "tValue") into tError
      put tValue into rDataA[ sCursorColumnsA[i] ]
    end if
  end repeat

  return tError
end _convertCurrentRowToArray
