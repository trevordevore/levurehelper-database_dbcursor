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
dispatch "RenderView" to group "MyDataView"

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
  end if
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


on deleteKey
  dispatch "DeleteSelectedRows" to me
end deleteKey


on backspaceKey
  dispatch "DeleteSelectedRows" to me
end backspaceKey


/**
Summary: Returns the `id` property of the selected row(s).

Description:
This property only returns a value if the cursor row has an `id` column.

Returns: Value
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
    return tIds
  else
    return empty
  end if
end dvHilitedIds


getProp dvHilitedId
  return the dvHilitedIds of me
end dvHilitedId


/**
Summary: Sets the selected row based on the `id` property of a row(s).

Description:
This property can only be set if the database cursor has an `id` column
that was selected as part of the cursor.

Returns: empty
*/
setProp dvHilitedIds pIds
  local tRows

  put _RowOfId(pIds) into tRows

  if tRows is not empty then
    set the dvHilitedRow of me to tRows
  end if

  return empty
end dvHilitedIds


setProp dvHilitedId pIds
  set the dvHilitedIds of me to pIds
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

Returns: nothing
*/
getProp dvRowId[pRow]
  local tDataA

  _moveToRecord pRow
  _convertCurrentRowToArray tDataA, "id"

  return tDataA["id"]
end dvRowId


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

  put _RowOfId(pId) into tRow

  if tRow > 0 then
    local tDataA
    _moveToRecord tRow
    _convertCurrentRowToArray tDataA
  else
    return empty
  end if
end dvRowOfIdData


/**
Summary: Returns the data array of the currently selected row.

Returns: Value
*/
getProp dvHilitedData
  local tRows

  put the dvHilitedRow of me into tRows

  if tRows is not empty then
    local tRowA

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
  else
    return empty
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

  put _RowOfId(pId) into tRow

  if tRow > 0 then
    RenderRows tRow
  end if

  return empty
end RefreshRowOfId


private command _setHilitedIds pIds
  local tId, tRow, tRows

  repeat for each item tId in pIds
    put _RowOfId(tId) & "," into tRow
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


private function _RowOfId pIds
  local i, tItemNo, tRows, tResult

  set the wholematches to true

  # start on current record and move backwards
  repeat with i = sCurrentRow down to 1
    put itemOffset(revDatabaseColumnNamed(sCursorId, "id"), pIds) into tItemNo
    if tItemNo > 0 then
      put i & "," after tRows
      delete item tItemNo of pIds
      if pIds is empty then
        exit repeat
      end if
    end if

    revMoveToPreviousRecord sCursorId
    if the result is true then
      put i into sCurrentRow
    end if
  end repeat

  # Now work our way back up through cursor
  if pIds is not empty and sCurrentRow < sRecordCount then
    revMoveToRecord sCursorId, sCurrentRow + 1
    if the result is "true" then
      add 1 to sCurrentRow

      repeat with i = sCurrentRow to sRecordCount
        put itemOffset(revDatabaseColumnNamed(sCursorId, "id"), pIds) into tItemNo
        if tItemNo > 0 then
          put i & "," after tRows
          delete item tItemNo of pIds
          if pIds is empty then
            exit repeat
          end if
        end if

        revMoveToNextRecord sCursorId
        if the result is true then
          put i into sCurrentRow
        end if
      end repeat
    end if
  end if

  delete the last char of tRows

  return tRows
end _RowOfId


private command _moveToRecord pRow
  revMoveToRecord sCursorId, pRow
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
