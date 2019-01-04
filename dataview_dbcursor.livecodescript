script "DataView Database Cursor Controller Behavior" with behavior "DataView Behavior"
local sCursorId
local sCursorColumnsA
local sColumnCount
local sRecordCount = 0
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
Summary: Returns the `id` property of the selected row.

Description:
This property only returns a value if the array created in `DataForRow`
has an `id` key.

Returns: Value
*/
getProp dvSelectedId
  local tRow

  put the dvHilitedRow of me into tRow

  if tRow > 0 then
    _moveToRecord tRow
    return revDatabaseColumnNamed(sCursorId, "id")
  else
    return empty
  end if
end dvSelectedId


/**
Summary: Sets the selected row based on the `id` property of a row.

Description:
This property can only be set if the array created in `DataForRow`
has an `id` key.

Returns: empty
*/
setProp dvSelectedId pId
  local tRow

  put _RowOfId(pId) into tRow

  if tRow > 0 then
    set the dvHilitedRow of me to tRow
  end if

  return empty
end dvSelectedId


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
getProp dvSelectedData
  local tRow

  put the dvHilitedRow of me into tRow

  if tRow > 0 then
    local tDataA
    _moveToRecord tRow
    _convertCurrentRowToArray tDataA
  else
    return empty
  end if
end dvSelectedData


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


private function _RowOfId pId
  local i

  # start on current record and move backwards
  repeat with i = sCurrentRow down to 1
    if revDatabaseColumnNamed(sCursorId, "id") is pId then
      put i into sCurrentRow
      return i
    end if
    revMoveToPreviousRecord sCursorId
  end repeat

  # Now work our way back up through cursor
  if sCurrentRow < sRecordCount then
    revMoveToRecord sCursorId, sCurrentRow + 1

    repeat with i = sCurrentRow + 1 to sRecordCount
      if revDatabaseColumnNamed(sCursorId, "id") is pId then
        put i into sCurrentRow
        return i
      end if
      revMoveToNextRecord sCursorId
    end repeat
  end if

  return 0
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
