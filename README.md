# DataView Database Cursor Helper

The DataView Database Cursor helper uses the data in a database cursor returned by `revQueryDatabase()` to feed a [DataView](https://github.com/trevordevore/levurehelper-dataview).

Note that this helper requires the [DataView helper](https://github.com/trevordevore/levurehelper-dataview).

## Demo

The DataView Demo application includes an example of using this helper:

https://github.com/trevordevore/dataview_demo

## Usage

To display data from a cursor in a DataView you will need to do two things:

1. Create a row template that will display each row's data.
2. Set the `dvCursor` property of the DataView and call `RenderView`.

Example:

```
put revQueryDatabase(tDatabaseId, "SELECT * FROM MyTable") into tCursorId
set the dvCursor of group "MyDataView" to tCursorId
dispatch "RenderView" to group "MyDataView"
```

Note that you are responsible for opening and closing the cursor. The DataView only navigates within the cursor. When you close the database cursor make sure you set the `dvCursor` to empty so that the DataView will not try to access the cursor again. When setting the `dvCursor` to empty the DataView Database Cursor helper will call `ResetView`. This will remove all data from the UI and not allow the user to scroll through any results (which would result in errors).
