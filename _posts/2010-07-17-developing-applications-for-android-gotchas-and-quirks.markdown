---
layout: post
title: Developing applications for Android – gotchas and quirks
date: '2010-07-17 07:28:24'
---

Over the past couple of days, I have developed my first two applications for the Android Market; [Tuples](https://play.google.com/store/apps/details?id=com.thesquareplanet.tuples) and [PencilWise](https://play.google.com/store/apps/details?id=com.thesquareplanet.pencilwise). The first is a simple tool for storing key-value pairs, or tuples, of information you need to remember such as your bank account numbers, your PGP fingerprints, etc.. The second is a mobile version of the [puzzle page](http://www.personal.psu.edu/bxb11/Pencilwise/Pencilwi.htm) by the same name.

As this was my first attempt at an Android application, I encountered quite a lot of first-time gotchas and quirks with the Android development platform, and I figured I'd share them here so others can resolve them quicker than I did. I'll also give some hints for how to accomplish common task,s such as strike-through text, that might not be as obvious as they should be.

All of this is based on Android 2.1, but I assume most of them apply to any 2.0+ API.

## Quirks and Gotchas

### View reuse

Since Android mostly runs on devices that lack in the area of processing power, several optimizations have been implemented in the core of the OS. Unfortunately, these can have some strange side-effects.

One of these optimizations is that Android reuses views (the common base class for all elements drawn on screen) once the given element is no longer in view on the screen. This means that any pointers you might have to a view, will actually point to whatever Android has reused the view as, not the element you originally thought it was.

An example of this annoyance can be observed in the following code:

```java
public class PencilWise extends ListActivity {
    View activeElement;
    // ...
    @Override
    public void onCreate ( Bundle savedInstanceState ) {
        // ...
        this.getListView( ).setOnItemClickListener ( new OnItemClickListener ( ) {
            public void onItemClick ( AdapterView<?> parent, View view, int position, long id ) {
                MyActivity.this.activeElement = view;
                MyActivity.this.showDialog ( DIALOG_ANSWER );
            }
        } );
    }
}
```

The showDialog method will display the answer dialog, which needs to know what question the user has opened. The problem is that by the time the dialog opens, the view passed to onItemClick might have been reused, and so activeElement would no longer point to the element the user clicked to open the dialog in the first place!

To achieve the desired effect, you need to store the position or the ID instead, and use something like: `this.getListAdapter ( ).getItem ( this.activeElement )`, which will return the cursor used to fetch the element behind the selected item.

### View reuse and formatting

A bi-product of the view reuse of Android is that formatting options on the view are actually kept when a View is reused. So, if you for instance set that a TextView should be painted with a strike-through (see further down), ever time Android reuses that view, the new view will also be striked even though you never explicitly made it so..

For instance, say you used a ListAdapter for a ListView as such: (*the getView method here is used to dynamically manipulate elements drawn in the List whenever they are accessed from the adapter. This can be used to, as shown in the example below, only strike through elements that hold true for a given condition*)

```java
this.setListAdapter ( new ArrayAdapter<String> ( this, android.R.layout.simple_list_item_1, new String[] { "Hello", "World" } ) {
    @Override
    public View getView ( int position, View convertView, ViewGroup parent ) {
        TextView v = (TextView) super.getView ( position, convertView, parent );
        if ( MyActivity.this.answered.getBoolean ( v.getText ( ).toString ( ), false ) )
            v.setPaintFlags ( v.getPaintFlags ( ) | Paint.STRIKE_THRU_TEXT_FLAG );
        return v;
    }
} );
```

This code would seemingly be working, but once you start getting lots of elements, and the user starts to scroll, you will see that apparently random elements get striked. This is because of view reuse.
The solution is to undo the paint flag if the condition is not true, like this:

```java
this.setListAdapter ( new ArrayAdapter<String> ( this, android.R.layout.simple_list_item_1, new String[] { "Hello", "World" } ) {
    @Override
    public View getView ( int position, View convertView, ViewGroup parent ) {
        TextView v = (TextView) super.getView ( position, convertView, parent );
        if ( MyActivity.this.answered.getBoolean ( v.getText ( ).toString ( ), false ) )
            v.setPaintFlags ( v.getPaintFlags ( ) | Paint.STRIKE_THRU_TEXT_FLAG );
        else
            v.setPaintFlags ( v.getPaintFlags ( ) & ~Paint.STRIKE_THRU_TEXT_FLAG );
        return v;
    }
} );
```

Now, each view will be drawn correctly.

### Dialog reuse

Android also reuses dialog boxes, which means that if you, for instance, have an input field in the dialog that the user types something in, closes the dialog, and opens another dialog with the same ID, the text will remain in the field. This can be very annoying if the value in the input field should depend on another action the user has performed (such as what element was clicked to open the dialog).

The obvious fix would be to reset the content of the text area whenever a dialog is created, which you would think would be done in the method `onCreateDialog` using something like this:

```java
@Override
protected Dialog onCreateDialog ( int id ) {
    // ...
    ( (EditText) dialog.findViewById ( R.id.text1 ) ).setText ( "" );
    // ...
}
```

Turns out, however, that this won't work, since `onCreateDialog` is only run once per dialog ID. The proper way is to also override `onPrepareDialog`, and do any dynamic changes to the dialog there. So, `onCreateDialog` is for setup/format, and `onPrepareDialog` is for manipulating content.

### Dynamic dialog titles/messages

After reading the above gotcha, you might also be tempted to put the `setTitle` and `setMessage` calls on the `AlertDialog` in `onPrepareDialog` since they might change between invocations of the dialog. The problem is that Android will not display the title or the message if they have not been set in the dialog returned from `onCreateDialog`. So, to use `setTitle` in `onPrepareDialog`, you have to make sure that you run `setTitle` in `onCreateDialog` with some placeholder text as well, otherwise your title/message calls in `onPrepareDialog` will not have any effect!

### Dealing with SQLite

SQLite is not as easy as it could be in Android, but the `SQLiteOpenHelper` class does help quite a bit.

In order to utilize SQLite in your application, you need a class representing each database you want to use that extends the class `SQLiteOpenHelper`. Each such class needs to define three methods:

 1. The constructor
 2. onUpgrade
 3. onCreate

The constructor will theoretically only contain line:

```java
super ( context, DATABASE_NAME, null, DATABASE_VERSION );
```

where `DATABASE_NAME` and `DATABASE_VERSION` are values defined by you to represent the current database. `DATABASE_NAME` can be any string, and `DATABASE_VERSION` should be an int that you will increment if you do any structural changes to your database.

This brings us to `onUpgrade`. This method is called if the database version number is different between the last time the app was run and this time (i.e. the user has updated your app in the market and the new version has a different DB schema). Here, you should provide update paths from every version of your database schema to the next such as adding/dropping tables and columns.

Finally, we have `onCreate`, which is called the first time the database is accessed. Here, you also usually only need a single statement per table you are creating: `db.execSQL ( TABLE_CREATE );` where db is the SQLiteDatabase object the method is passed and `TABLE_CREATE` is the SQL statement used to create the given table.

When accessing your database later, you need to call the method `getReadableDatabase()` or `getWritableDatabase()` on your helper class instance object to actually execute `query()`, `delete()`, `insert()` and `update()` statements.

### SQLite and CursorAdapters - Where the fun starts

There is one little quirk that is not very well advertised in the SDK documentation for Android, and that is the fact that all Cursor objects used as source for list adapters MUST have an ID column. And not just any ID column, but one with the name set in `BaseColumns._ID` and a type of `INTEGER PRIMARY KEY AUTOINCREMENT`. So, if you intend to use any table in `SimpleCursorAdapter` or `CursorAdapter`, make sure your `CREATE_TABLE` statement includes the column

```
BaseColumns._ID + " INTEGER PRIMARY KEY AUTOINCREMENT"
```

### Handling screen orientation changes

Android has another quirk that caused me quite a bit of headache when a bug was reported a couple of days ago:

> If a dialog box is open, and the user changes the orientation of the screen, the dialog box no longer contains the data from before the screen flip.

Turns out, whenever the screen orientation is changed, Android actually relaunches the current activity, thereby resetting all instance variables of that class! Thus, if I render the contents of the dialog based on what element in a list a user clicked (which is quite common), and the id of the element the user clicked is stored in `this.activeElement`; when the user changes orientation, that variable is reset to 0, and the code in `onPrepareDialog` does not know what element was originally pressed any more. This leads to it not changing the content, and only the structure from `onCreateDialog` is actually used (i.e. the title is only set to `__`).

After digging a bit around, I came upon [this blog post](http://www.linux-mag.com/id/7778/) dealing with the problem.

The solution is to use what Android refers to as an Application. This is kind of like a global registry for all of your application that will remain unchanged as long as your program runs. Thus, we can store any instance variables there, and access instance variables like this:

First, we create a new file holding the application class:

```java
public class MyApplication extends Application {
    public int activeElement = -1;
}
```

Next, we define in our application manifest (`AndroidManifest.xml`) what our application class is

```
<application [...] android:name="MyApplication">
```

And now, we can access variables from our activities using:

```
( (MyApplication) this.getApplication ( ) ).activeElement;
```

It might be good to define a getter and setter in your activity for ease of use:

```
private int getActiveElement ( ) {
    return ( (MyApplication) this.getApplication ( ) ).activeElement;
}

private void setActiveElement ( int element ) {
    ( (MyApplication) this.getApplication ( ) ).activeElement = element;
}
```

## How-tos

### Strike-through text

Given a TextView view `v`, use:

```
v.setPaintFlags ( v.getPaintFlags ( ) | Paint.STRIKE_THRU_TEXT_FLAG );
```

To undo the strike-through, we use some bitwise magic:

```
v.setPaintFlags ( v.getPaintFlags ( ) & ~Paint.STRIKE_THRU_TEXT_FLAG );
```

### Redraw all elements in a ListView

If you use an ArrayAdapter a, you can call

```
a.notifyDataSetChanged();
```

If you use an ArrayAdapter in a ListActivity:

```
( (ArrayAdapter) this.getListAdapter ( ) ).notifyDataSetChanged ( );
```

If you have a ListView `lv` that uses an adapter that implements CursorAdapter, use:

```
((CursorAdapter) lv.getListAdapter()).getCursor().requery();
```

### More flexible string handling through resources

Say you want to output the string `Hint: ` followed by some dynamically fetched hint. Your first thought might be to hard code `"Hint: " + this.getHint()`, but it should be apparent that this is not the right way to do it. Android provides the `strings.xml` file for exactly this purpose. So, we define a string by the name of `hint_text` in `strings.xml` with the content `Hint: `. How do we access this string from our code?

Well, from any activity you can do this by simply calling `this.getString` which takes the ID of the string resource. In our case this would be

```
this.getString ( R.string.hint_text )
```

With our code looking like this (to put this in a toast):

```
Toast.makeText ( this, this.getString ( R.string.hint ) + this.getHint ( ), Toast.LENGTH_SHORT ).show ( );
```

You then happily compile and run the code, just to see that your text gets printed out as `Hint:Some hint` without the space you put in. The reason for this is that XML trims spaces inside elements, and as such, your space is lost. There are two wrong ways of fixing this, and one right one. The wrong ones are:

 - Use the XML entity for a space:
 - Hardcode the space in your string concatenation in Java

If you want to do it properly, you define your string like this:

```
<string name="hint_text">Hint: %s</string>
```

For those of you familiar with the printf family of functions, this should look familiar. What we are doing here is to tell Android that our string will contain dynamic content (here a string, represented by `%s`). We can then give the data that should be inserted into the text as additional parameters to the `getString` method like this:

```
Toast.makeText ( this, this.getString ( R.string.hint, this.getHint ( ) ), Toast.LENGTH_SHORT ).show ( );
```