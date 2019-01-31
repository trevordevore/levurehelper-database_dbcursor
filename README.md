# DataView Database Cursor Helper

The DataView Database Cursor helper uses the data in a database cursor returned by `revQueryDatabase()` to feed a [DataView](https://github.com/trevordevore/levurehelper-dataview).

Note that this helper requires the [DataView helper](https://github.com/trevordevore/levurehelper-dataview).

## Demo

The DataView Demo application includes an example of using this helper:

https://github.com/trevordevore/dataview_demo

## Usage

To display data from a cursor in a DataView you will need to do two things:

1. Create a row template that will display each row's data.
2. Set the `dvCursor` property of the DataView.

Example:

```
put revQueryDatabase(tDatabaseId, "SELECT * FROM MyTable") into tCursorId
set the dvCursor of group "MyDataView" to tCursorId
```

Note that you are responsible for opening and closing the cursor. The DataView only navigates within the cursor. When you close the database cursor make sure you set the `dvCursor` to empty so that the DataView will not try to access the cursor again. When setting the `dvCursor` to empty the DataView Database Cursor helper will call `ResetView`. This will remove all data from the UI and not allow the user to scroll through any results (which would result in errors).

## API

- [dvCursor](#dvCursor)
- [dvHilitedData](#dvHilitedData)
- [dvHilitedIds](#dvHilitedIds)
- [dvHilitedIds[pForceScroll]](#dvHilitedIds[pForceScroll])
- [dvRowData[pRow]](#dvRowData[pRow])
>
- [dvRowId[pRow]](#dvRowId[pRow])
- [dvRowOfId[pId]](#dvRowOfId[pId])
- [dvRowOfIdData[pId]](#dvRowOfIdData[pId])
- [GetValueForKeyInRow](#GetValueForKeyInRow)
- [RefreshRowOfId](#RefreshRowOfId)

<br>

## <a name="dvCursor"></a>dvCursor

**Type**: setProp

**Syntax**: `dvCursor <pCursorId>`

**Summary**: Set the database cursor that will feed the DataView.

**Returns**: nothing

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pCursorId` |  A cursor id as returned by `revQueryDatabase()`. |

**Examples**:
```
put revQueryDatabase(tDatabaseId, "SELECT * FROM MyTable") into tCursorId
set the dvCursor of group "MyDataView" to tCursorId
```

<br>

## <a name="dvHilitedData"></a>dvHilitedData

**Type**: getProp

**Syntax**: `dvHilitedData `

**Summary**: Returns the data array of the currently selected row.

**Returns**: Array

**Description**:

If a single row is selected then the array associated with that row
will be returned. If multiple rows are selected, then the result will
be a numerically indexed array of row data.

<br>

## <a name="dvHilitedIds"></a>dvHilitedIds

**Type**: getProp

**Syntax**: `dvHilitedIds `

**Summary**: Returns the `id` property of the selected row(s).

**Returns**: Comma-delimited list of row numbers.

**Description**:

This property only returns a value if the cursor row has an `id` column.
If there is no `id` column then an empty value will be returned for each
selected row.

<br>

## <a name="dvHilitedIds[pForceScroll]"></a>dvHilitedIds[pForceScroll]

**Type**: setProp

**Syntax**: `dvHilitedIds[pForceScroll] <pIds>`

**Summary**: Sets the selected row based on the `id` property of a row(s).

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pIds` |  The ids to select. |

**Description**:

This property can only be set if the database cursor has an `id` column
that was selected as part of the cursor.

In order to find the rows associated with each the code will loop through
the database cursor. This may be slow for large data sets so test to make
sure the speed is acceptable.


<br>

## <a name="dvRowData[pRow]"></a>dvRowData[pRow]

**Type**: getProp

**Syntax**: `dvRowData[pRow] `

**Summary**: Returns the row data associated with `pRow`.

**Returns**: Value

<br>

## <a name="dvRowId[pRow]"></a>dvRowId[pRow]

**Type**: getProp

**Syntax**: `dvRowId[pRow] `

**Summary**: Returns the row id associated with `pRow`.

**Returns**: Value

**Description**:

This property can only be set if the array created in `DataForRow`
has an `id` key.

<br>

## <a name="dvRowOfId[pId]"></a>dvRowOfId[pId]

**Type**: getProp

**Syntax**: `dvRowOfId[pId] `

**Summary**: Returns the row(s) associated with the provided ids.

**Returns**: Integer

**Description**:

If the id is not found then 0 is returned.

<br>

## <a name="dvRowOfIdData[pId]"></a>dvRowOfIdData[pId]

**Type**: getProp

**Syntax**: `dvRowOfIdData[pId] `

**Summary**: Returns the row data associated with a specific `id`.

**Returns**: Value

**Description**:

This property can only be set if the array created in `DataForRow`
has an `id` key.

<br>

## <a name="GetValueForKeyInRow"></a>GetValueForKeyInRow

**Type**: function

**Syntax**: `GetValueForKeyInRow(<pRow>,<pKey>)`

**Summary**: Returns a specific key in a row's array.

**Returns**: Mixed

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pRow` |  The target row. |
| `pKey` |  The custom key. |

<br>

## <a name="RefreshRowOfId"></a>RefreshRowOfId

**Type**: command

**Syntax**: `RefreshRowOfId <pId>`

**Summary**: Redraws the row associated with the specified `id`.

**Returns**: nothing

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pId` |  The target id. |

**Description**:

Call this command after updating data in the DataView affects what is
displayed in the row.


