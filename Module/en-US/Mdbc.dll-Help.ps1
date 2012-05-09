
<#
.Synopsis
	Help script (https://github.com/nightroman/Helps)
#>

# Import the module to make commands available for the builder.
Import-Module Mdbc

# Description of the Collection parameter.
$script:CollectionParameter = @'
Collection object. It is obtained by Connect-Mdbc directly (using the
Collection parameter) or from returned database or server objects.
'@

# Description of the Query parameter.
$script:QueryParameter = @'
Specifies documents to be processed. Supported types:
1) MongoDB.Driver.IMongoQuery (see New-MdbcQuery);
2) documents with _id (BsonDocument or Mdbc.Dictionary);
3) other values are treated as _id and converted to queries.
'@

# Shared [Mdbc.Dictionary] type info.
$script:TypeMdbcDictionary = @{
	type = '[Mdbc.Dictionary]'
	description = 'Objects created by New-MdbcData or obtained by Get-MdbcData.'
}

# Shared SafeModeResult type info.
$script:TypeSafeModeResult = @{
	type = '[MongoDB.Driver.SafeModeResult]'
	description = 'The result is returned if safe mode if enabled.'
}

# Query inputs.
$script:QueryInputs = @(
	@{
		type = '[MongoDB.Driver.IMongoQuery]'
		description = 'Query expression. See New-MdbcQuery (query).'
	}
	@{
		type = '[Mdbc.Dictionary], [MongoDB.Bson.BsonDocument]'
		description = @'
A document which _id is used for identification.
[Mdbc.Dictionary] objects are created by New-MdbcData or obtained by Get-MdbcData.
'@
	}
	@{
		type = '[object]'
		description = 'Any other value is treated as _id for identification.'
	}
)


### Connect-Mdbc
@{
	command = 'Connect-Mdbc'
	synopsis = 'Connects and gets a server, database(s), or collection(s) object(s).'
	description = @'
	> Connect-Mdbc -ConnectionString
	Gets the connected server object.

	> Connect-Mdbc -ConnectionString -Database
	Gets the connected database object.

	> Connect-Mdbc -ConnectionString -Database -Collection
	Gets the connected collection object. Use Add-MdbcData, Get-MdbcData, Remove-MdbcData, Update-MdbcData.
'@

	parameters = @{
		ConnectionString = @'
	Connection string (see the C# driver manual for details):
	mongodb://[username:password@]hostname[:port][/[database][?options]]
	"." is used for the default C# driver connection ("mongodb://localhost").
	Examples:
	mongodb://localhost:27017
	mongodb://localhost/?safe=true
'@
		Database = 'Database name. * is used in order to get all database objects.'
		Collection = 'Collection name. * is used in order to get all collection objects.'
		NewCollection = 'Tells to drop the collection if it exists and create a new one.'
	}
	inputs = @()
	outputs = @(
		@{ type = '[MongoDB.Driver.MongoServer]' }
		@{ type = '[MongoDB.Driver.MongoDatabase]' }
		@{ type = '[MongoDB.Driver.MongoCollection]' }
	)
	examples = @(
		@{
			code = {
				# Connect and get the collection (drop existing, create new)
				Import-Module Mdbc
				$collection = Connect-Mdbc . test test -NewCollection
			}
			test = {
				. $args[0]
				if ($collection.GetType().Name -ne 'MongoCollection`1') { throw }
			}
		}
		@{
			code = {
				# Connect and get the database
				Import-Module Mdbc
				$database = Connect-Mdbc . test

				# Then get collections
				$collection1 = $database.GetCollection('test')
				$collection2 = $database.GetCollection('process')
			}
			test = {
				. $args[0]
				if ($database.GetType().Name -ne 'MongoDatabase') { throw }
				if ($collection1.FullName -ne 'test.test' ) { throw }
				if ($collection2.FullName -ne 'test.process' ) { throw }
			}
		}
		@{
			code = {
				# Connect and get the server
				Import-Module Mdbc
				$server = Connect-Mdbc mongodb://localhost

				# Then get the database
				$database = $server.GetDatabase('test')
			}
			test = {
				. $args[0]
				if ($server.GetType().Name -ne 'MongoServer') { throw }
				if ($database.GetType().Name -ne 'MongoDatabase') { throw }
			}
		}
		@{
			code = {
				# Connect to the default server and get all databases
				Import-Module Mdbc
				Connect-Mdbc . *
			}
			test = {
				$database = . $args[0]
				# at least: local, test
				if ($database.Count -lt 2) { throw }
				if ($database[0].GetType().Name -ne 'MongoDatabase') { throw }
			}
		}
		@{
			code = {
				# Connect to the database 'test' and get all its collections
				Import-Module Mdbc
				Connect-Mdbc . test *
			}
			test = {
				$collection = . $args[0]
				# at least: test, process
				if ($collection.Count -lt 2) { throw }
				if ($collection[0].GetType().Name -ne 'MongoCollection`1') { throw }
			}
		}
	)
	links = @(
		@{ text = 'Add-MdbcData' }
		@{ text = 'Get-MdbcData' }
		@{ text = 'Remove-MdbcData' }
		@{ text = 'Update-MdbcData' }
		@{ text = 'MongoDB'; URI = 'http://www.mongodb.org/' }
		@{ text = 'C# driver'; URI = 'http://www.mongodb.org/display/DOCS/CSharp+Driver+Tutorial' }
	)
}

### New-MdbcData
@{
	command = 'New-MdbcData'
	synopsis = 'Creates data documents and some other C# driver types.'
	description = @'
This command is mostly used in order to create documents to be stored in the database.
Without input objects it creates PowerShell friendly wrappers of C# driver documents.
'@
	parameters = @{
		DocumentId = @'
Sets the document _id to the specified value.
It makes sense when a document is being created.

With pipeline input it can be a script block that returns an ID value.
If this ID is an existing property/key value then the Select list should be specified.
Otherwise the same value is included twice as the document ID and the property/key value.
'@
		NewDocumentId = @'
Tells to generate and set a new document _id.
It makes sense when a document is being created.
'@
		InputObject = @'
.NET value to be converted to its BSON analogue.
'@
		Property = @'
Property or key names which values are to be included into new documents.
This parameter is used when input objects are converted into documents (see examples).
'@
	}
	inputs = @(
		@{
			type = '$null, [PSCustomObject], [Hashtable] (any dictionary, in fact)'
			description = @'
[Mdbc.Dictionary] document is created (BsonDocument helper).
The created document is empty if the input object is $null or empty.
Otherwise the document has the same fields and values as the input properties/keys and values.
'@
		}
		@{ type = '[System.Collections.IEnumerable]'; description = 'Mdbc array is created (BsonArray helper).' }
		@{ type = '[bool]'; description = 'is converted to BsonBoolean.' }
		@{ type = '[DateTime]'; description = 'is converted to BsonDateTime.' }
		@{ type = '[double]'; description = 'is converted to BsonDouble.' }
		@{ type = '[Guid]'; description = 'is converted to BsonBinaryData (and retrieved back as [Guid].' }
		@{ type = '[int]'; description = 'is converted to BsonInt32.' }
		@{ type = '[long]'; description = 'is converted to BsonInt64.' }
		@{ type = '[string]'; description = 'is converted to BsonString.' }
	)
	outputs = @(
		@{
			type = '[Mdbc.Dictionary]'
			description = 'PowerShell friendly wrapper of BsonDocument.'
		}
		@{
			type = '[Mdbc.Collection]'
			description = 'PowerShell friendly wrapper of BsonArray.'
		}
		@{
			type = '[MongoDB.Bson.BsonValue]'
			description = 'Other BsonValue types created from input objects.'
		}
	)
	examples = @(
		@{
			code = {
				# Connect and get the collection
				Import-Module Mdbc
				$collection = Connect-Mdbc . test test -NewCollection

				# Create a new document, set some data
				$data = New-MdbcData -DocumentId 12345
				$data.Text = 'Hello world'
				$data.Date = Get-Date

				# Add the document to the database
				$data | Add-MdbcData $collection

				# Query the document from the database
				$result = Get-MdbcData $collection (New-MdbcQuery _id 12345)
				$result
			}
			test = {
				. $args[0]
				if ($result.Text -ne 'Hello world') { throw }
			}
		}
		@{
			code = {
				# Connect and get the collection
				Import-Module Mdbc
				$collection = Connect-Mdbc . test test -NewCollection

				# Create data from input objects and add to the database
				Get-Process mongod |
				New-MdbcData -DocumentId {$_.Id} -Property Name, WorkingSet, StartTime |
				Add-MdbcData $collection

				# Query the data
				$result = Get-MdbcData $collection
				$result
			}
			test = {
				. $args[0]
				$result = @($result)
				if ($result[0].Name -ne 'mongod') { throw }
			}
		}
	)
	links = @(
		@{ text = 'Add-MdbcData' }
	)
}

### New-MdbcQuery
@{
	command = 'New-MdbcQuery'
	synopsis = 'Creates queries for Get-MdbcData, Remove-MdbcData, and Update-MdbcData.'
	sets = @{
		Where = '{ $where: "this.a > 3" }', @'
The database evaluates JavaScript expression for each object scanned. When the
result is true, the object is returned in the query results.
'@,
		@'
JavaScript executes more slowly than the native operators but is very flexible.
See the server-side processing page for more information (official site).
'@
	}
	parameters = @{
		Where = '$where argument, JavaScript Boolean expression.'
		And = @'
Queries for logical And.
'@
		Nor = @'
Queries for logical Nor (MongoDB $nor).
'@
		Or = @'
Queries for logical Or (MongoDB $or).
'@
		Name = @'
Field name.
'@
		EQ = @'
Equality test. Parameter name is optional. Parameter value can be null.
It is not combined with other query tests.
'@
		IEQ = @'
Ignore case equality test for strings (no MongoDB analogue).
It is not combined with other query tests.
'@
		INE = @'
Ignore case inequality test for strings (no MongoDB analogue).
It is not combined with other query tests.
'@
		Match = @'
Regular expression test (MongoDB /.../imxs values, $regex and $options operators).
It is not combined with other query tests.
'@,
		@'
Value is an array of one or two items.
A single item is either a regular expression string pattern or a regular expression object.
Two items are both strings: a regular expression pattern and options, combination of 'i', 'm', 'x', 's' characters.
'@
		Not = @'
Tells to negate the whole query expression (MongoDB $not).
'@
		GE = @'
Greater or equal test (MongoDB $gte).
'@
		GT = @'
Greater than test (MongoDB $gt).
'@
		LE = @'
Less or equal test (MongoDB $lte).
'@
		LT = @'
Less than test (MongoDB $lt).
'@
		NE = @'
Inequality test (MongoDB $ne).
'@
		Exists = @'
Checks if the field exists (MongoDB $exists).
'@
		Matches = @'
Checks if an element in an array matches the specified query expression (MongoDB $elemMatch).
'@,
		@'
It is needed only when more than one field must be matched in the array element.
'@
		Mod = @'
Modulo test (MongoDB $mod).
The argument is an array or two items: the modulus and the result value to be tested.
'@
		Size = @'
Array element item count test (MongoDB $size).
'@
		Type = @'
Element type test (MongoDB $type).
'@
		All = @'
Checks if all the field values are in the specified set (MongoDB $all).
'@
		In = @'
Checks if the field has any value is in the specified set (MongoDB $in).
'@
		NotIn = @'
Checks if the field does not have any value in the specified set (MongoDB $nin).
'@
	}
	inputs = @()
	outputs = @{
		type = '[MongoDB.Driver.IMongoQuery]'
		description = 'Use it for Get-MdbcData, Remove-MdbcData, Update-MdbcData.'
	}
	links = @(
		@{ text = 'Get-MdbcData' }
		@{ text = 'Remove-MdbcData' }
		@{ text = 'Update-MdbcData' }
		@{ text = 'Advanced Queries'; URI = 'http://www.mongodb.org/display/DOCS/Advanced+Queries' }
	)
}

### New-MdbcUpdate
@{
	command = 'New-MdbcUpdate'
	synopsis = 'Creates update expressions for Update-MdbcData.'
	sets = @{
		AddToSet = '{ $addToSet : { field : value } }', @'
Adds value to the array only if its not in the array already, if field is an
existing array, otherwise sets field to the array value if field is not
present. If field is present but is not an array, an error condition is raised.
'@
		AddToSetEach = '{ $addToSet : { a : { $each : [ 3 , 5 , 6 ] } } }', @'
To add many values.
'@
		Band = '{ $bit : { field : { and : 5 } } }', @'
Does a bitwise-and update of field. Can only be used with integers.
'@
		Bor = '{ $bit : { field : { or : 5 } } }', @'
Does a bitwise-or update of field. Can only be used with integers.
'@
		Increment = '{ $inc : { field : value } }', @'
Increments field by the number value if field is present in the object,
otherwise sets field to the number value.
'@
		PopFirst = '{ $pop : { field : -1  } }', @'
Removes the first element in an array.
'@
		PopLast = '{ $pop : { field : 1  } }', @'
Removes the last element in an array.
'@
		Pull = '{ $pull : { field : value } }', @'
Removes all occurrences of value from field, if field is an array. If field is
present but is not an array, an error condition is raised.
'@,
'{ $pull : { field : {<match-criteria>} } }', @'
Removes array elements meeting match criteria.
'@
		PullAll = '{ $pullAll : { field : value_array } }', @'
Removes all occurrences of each value in value_array from field, if field is an
array. If field is present but is not an array, an error condition is raised.
'@
		Push = '{ $push : { field : value } }', @'
Appends value to field, if field is an existing array, otherwise sets field to
the array [value] if field is not present. If field is present but is not an
array, an error condition is raised.
'@
		PushAll = '{ $pushAll : { field : value_array } }', @'
Appends each value in value_array to field, if field is an existing array,
otherwise sets field to the array value_array if field is not present. If field
is present but is not an array, an error condition is raised.
'@
		Rename = '{ $rename : { old_field_name : new_field_name } }', @'
Renames the field with name 'old_field_name' to 'new_field_name'. Does not
expand arrays to find a match for 'old_field_name'.
'@
		Set = '{ $set : { field : value } }', @'
Sets field to value. All data types are supported.
'@
		Unset = '{ $unset : { field : 1} }', @'
Deletes a given field.
'@
	}
	parameters = @{
		Name = 'Name of a field to be updated.'
		AddToSet = '$addToSet argument. If it is a collection then it is treated as a single value to add.'
		AddToSetEach = '$addToSet $each argument, a collection of values, each value is added.'
		Band = '$bit "and" argument, [int] or [long].'
		Bor = '$bit "or" argument, [int] or [long].'
		Increment = '$inc argument, [int], [long], or [double].'
		PopFirst = 'Tells to remove the first element in an array.'
		PopLast = 'Tells to remove the last element in an array.'
		Pull = '$pull argument, a value or a query. If it is a collection then it is treated as a single value to pull.'
		PullAll = '$pullAll argument, a collection of values, each value is pulled.'
		Push = '$push argument. If it is a collection then it is treated as a single value to push.'
		PushAll = '$pushAll argument, a collection of values, each value is pushed.'
		Rename = '$rename argument, the new field name.'
		Set = '$set argument. All standard types are supported.'
		Unset = 'Tells to remove the field.'
	}
	inputs = @()
	outputs = @{ type = 'Update expression'; description = 'Use these expression objects for Update-MdbcData.' }
	links = @(
		@{ text = 'Update-MdbcData' }
	)
}

### Add-MdbcData
@{
	command = 'Add-MdbcData'
	synopsis = 'Adds new documents to the database collection or updates existing.'
	parameters = @{
		Collection = $script:CollectionParameter
		InputObject = 'Document (Mdbc.Dictionary, BsonDocument, or PSCustomObject).'
		Safe = 'Tells to enable safe mode.'
		SafeMode = 'Advanced safe mode options.'
		Update = 'Tells to update existing documents with the same _id or add new documents otherwise.'
	}
	inputs = @(
		$script:TypeMdbcDictionary
		@{
			type = '[PSCustomObject]'
			description = 'Custom objects often created by Select-Object but not only.'
		}
		@{
			type = '[MongoDB.Bson.BsonDocument]'
			description = 'This type is supported but normally it should not be used directly.'
		}
	)
	outputs = $script:TypeSafeModeResult
	links = @(
		@{ text = 'New-MdbcData' }
		@{ text = 'Select-Object' }
	)
}

### Get-MdbcData
@{
	command = 'Get-MdbcData'
	synopsis = @'
Gets documents or data from the database collection.
'@
	Description = @'
Gets documents or other information from the database collection.

By default documents are represented by the Mdbc.Dictionary type which wraps
BsonDocument objects. This is the fastest way to obtain query results and the
type is friendly enough for using in scripts.

It is sometimes more convenient to get data as custom types (use the parameter
As) or as PS objects (use the switch AsCustomObject). Note that use of custom
types is not always possible and performance of PS objects is not always good
enough. Moreover, PS object property names are case insensitive unlike document
field names.

--------------------------------------------------
'@
	sets = @{
		All = 'Gets documents.'
		Count = 'Gets document count.'
		Cursor = 'Gets the result cursor.'
		Distinct = 'Gets distinct field values.'
		Remove = 'Removes and gets the first document specified by Query and SortBy.'
		Update = 'Updates and gets the first document specified by Query and SortBy.'
	}
	parameters = @{
		Collection = $script:CollectionParameter
		Query = $script:QueryParameter
		As = @'
The custom type of returned documents. The type members must be compatible with
a query unless a custom serialization is registered for the type.
'@
		AsCustomObject = @'
Tells to return documents represented by PSObject. PS objects are convenient in
some scenarios, especially interactive. Performance is not always good enough.
'@
		Count = @'
Tells to return the number of all documents or documents that match a query.
The First and Skip values are taken into account.
'@
		Cursor = @'
Tells to return a cursor to be used for further operations.
See the C# driver manual.
'@
		Distinct = @'
Tells to return distinct values for a given field for all documents or
documents that match a query.
'@
		Remove = @'
Tells to remove and get the first document specified by Query and SortBy.
'@
		Update = @'
Tells to update and get the first document specified by Query and SortBy.
'@
		New = @'
Tells to return the new document on Update.
By default the old document is returned.
'@
		Add = @'
Tells to add a new document on Update if the old document does not exist.
'@
		Property = @'
Subset of fields to be retrieved. The document _id is always included, thus,
expressions @() and _id are the same.
'@
		SortBy = @'
Specifies sorting field names and directions. Values are either field names or
hashtables with single entries: @{Field = <Boolean>}. True and false or their
equivalents (say, 1 and 0) are for ascending and descending directions.
'@
		Modes = @'
Additional query options.
See the C# driver manual.
'@
		First = @'
Specifies the number of first documents to be returned.
'@
		Last = @'
Specifies the number of last documents to be returned.
'@
		Skip = @'
Number of documents to skip from the beginning or from the end if Last is
specified.
'@
	}
	inputs = @()
	outputs = @(
		@{
			type = 'Int64'
			description = 'If the Count or Size switch is specified.'
		}
		@{
			type = 'object[]'
			description = 'If the Distinct field name is specified.'
		}
		@{
			type = 'MongoDB.Driver.MongoCursor'
			description = 'If the Cursor switch is specified.'
		}
		@{
			type = 'Mdbc.Dictionary[]'
			description = 'Query results, BSON document wrapper objects.'
		}
	)
	links = @(
		@{ text = 'Connect-Mdbc' }
		@{ text = 'New-MdbcQuery' }
	)
}

### Remove-MdbcData
@{
	command = 'Remove-MdbcData'
	synopsis = 'Removes specified documents from the collection.'
	description = ''
	parameters = @{
		Collection = $script:CollectionParameter
		Query = $script:QueryParameter
		Modes = 'Additional removal flags. See the C# driver manual.'
		Safe = 'Tells to enable safe mode.'
		SafeMode = 'Advanced safe mode options.'
	}
	inputs = $script:QueryInputs
	outputs = $script:TypeSafeModeResult
	links = @(
		@{ text = 'Connect-Mdbc' }
		@{ text = 'New-MdbcQuery' }
	)
}

### Update-MdbcData
@{
	command = 'Update-MdbcData'
	synopsis = 'Updates the specified documents.'
	description = ''
	parameters = @{
		Collection = $script:CollectionParameter
		Query = $script:QueryParameter
		Modes = 'Additional update flags. See the C# driver manual.'
		Safe = 'Tells to enable safe mode.'
		SafeMode = 'Advanced safe mode options.'
		Update = 'Update expressions. See New-MdbcUpdate.'
	}
	inputs = $script:QueryInputs
	outputs = $script:TypeSafeModeResult
	links = @(
		@{ text = 'Connect-Mdbc' }
		@{ text = 'New-MdbcUpdate' }
	)
}

### Add-MdbcCollection
@{
	command = 'Add-MdbcCollection'
	synopsis = 'Creates a new collection in a database.'
	description = @'
This cmdlet is needed only for creation of collections with extra options, like
capped collections. Ordinary collections do not have to be added explicitly.
'@
	parameters = @{
		Database = @'
The database where a new collection is created.
'@
		Name = @'
The name of a new collection.
'@
		MaxSize = @'
Sets the max size of a capped collection.
'@
		MaxDocuments = @'
Sets the max number of documents in a capped collection in addition to MaxSize.
'@
		AutoIndexId = @'
It may be set to true or false to explicitly enable or disable automatic
creation of a unique key index on the _id field.
'@
	}
	inputs = @()
	outputs = @()
}
