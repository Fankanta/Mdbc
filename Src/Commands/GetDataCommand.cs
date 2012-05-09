﻿
/* Copyright 2011-2012 Roman Kuzmin
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

using System;
using System.Management.Automation;
using MongoDB.Bson;
using MongoDB.Driver;
namespace Mdbc.Commands
{
	[Cmdlet(VerbsCommon.Get, "MdbcData", DefaultParameterSetName = "All")]
	public sealed class GetDataCommand : AbstractCollectionCommand
	{
		[Parameter(Position = 1)]
		public PSObject Query { get; set; }
		[Parameter(Mandatory = true, ParameterSetName = "Distinct")]
		public string Distinct { get; set; }
		[Parameter(Mandatory = true, ParameterSetName = "Count")]
		public SwitchParameter Count { get; set; }
		[Parameter(Mandatory = true, ParameterSetName = "Cursor")]
		public SwitchParameter Cursor { get; set; }
		[Parameter(Mandatory = true, ParameterSetName = "Remove")]
		public SwitchParameter Remove { get; set; }
		[Parameter(Mandatory = true, ParameterSetName = "Update")]
		public PSObject Update { get; set; }
		[Parameter(ParameterSetName = "Update")]
		public SwitchParameter New { get; set; }
		[Parameter(ParameterSetName = "Update")]
		public SwitchParameter Add { get; set; }
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Count")]
		[Parameter(ParameterSetName = "Cursor")]
		[Parameter(ParameterSetName = "Remove")]
		[Parameter(ParameterSetName = "Update")]
		public QueryFlags Modes { get; set; }
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Count")]
		[Parameter(ParameterSetName = "Cursor")]
		[Alias("Limit")]
		public int First { get; set; }
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Count")]
		[Parameter(ParameterSetName = "Cursor")]
		public int Last { get; set; }
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Count")]
		[Parameter(ParameterSetName = "Cursor")]
		public int Skip { get; set; }
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Cursor")]
		[Parameter(ParameterSetName = "Update")]
		[Alias("Select")]
		public string[] Property { get; set; }
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Cursor")]
		[Parameter(ParameterSetName = "Remove")]
		[Parameter(ParameterSetName = "Update")]
		public object[] SortBy { get; set; }
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Cursor")]
		public Type As { get; set; }
		[Parameter(ParameterSetName = "All")]
		[Parameter(ParameterSetName = "Cursor")]
		public SwitchParameter AsCustomObject { get; set; }
		void DoCount()
		{
			WriteObject(Collection.Count(Actor.ObjectToQuery(Query)));
		}
		void DoDistinct()
		{
			var data = Collection.Distinct(Distinct, Actor.ObjectToQuery(Query));
			foreach (var it in data)
				WriteObject(Actor.ToObject(it));
		}
		void DoModified(FindAndModifyResult result)
		{
			if (result.ModifiedDocument != null)
				WriteObject(new Dictionary(result.ModifiedDocument));

			if (!result.Ok)
				WriteError(new ErrorRecord(new RuntimeException(result.ErrorMessage), "Driver", ErrorCategory.InvalidResult, result));
		}
		void DoRemove()
		{
			var result = Collection.FindAndRemove(Actor.ObjectToQuery(Query), Actor.ObjectsToSortBy(SortBy));
			DoModified(result);
		}
		void DoUpdate()
		{
			var result = Collection.FindAndModify(Actor.ObjectToQuery(Query), Actor.ObjectsToSortBy(SortBy), Actor.ObjectToUpdate(Update), New, Add);
			DoModified(result);
		}
		Type GetDocumentType()
		{
			return AsCustomObject ? typeof(PSObject) : As ?? typeof(BsonDocument);
		}
		protected override void BeginProcessing()
		{
			switch (ParameterSetName)
			{
				case "Count":
					if (First > 0 || Skip > 0)
						break;
					DoCount();
					return;

				case "Distinct":
					DoDistinct();
					return;

				case "Remove":
					DoRemove();
					return;

				case "Update":
					DoUpdate();
					return;
			}

			var documentType = GetDocumentType();
			var query = Actor.ObjectToQuery(Query);
			var cursor = Collection.FindAs(documentType, query);

			if (Modes != QueryFlags.None)
				cursor.SetFlags(Modes);

			if (Last > 0)
			{
				Skip = (int)Collection.Count(query) - Skip - Last;
				First = Last;
				if (Skip < 0)
				{
					First += Skip;
					if (First <= 0)
					{
						if (Count)
							WriteObject(0);
						return;
					}
					Skip = 0;
				}
			}

			if (First > 0)
				cursor.SetLimit(First);
			
			if (Skip > 0)
				cursor.SetSkip(Skip);

			if (Count)
			{
				WriteObject(cursor.Size());
				return;
			}

			if (SortBy != null)
				cursor.SetSortOrder(Actor.ObjectsToSortBy(SortBy));

			if (Property != null)
				cursor.SetFields(Property);

			if (Cursor)
			{
				WriteObject(cursor);
				return;
			}

			if (documentType == typeof(BsonDocument))
			{
				foreach (BsonDocument bson in cursor)
					WriteObject(new Dictionary(bson));
			}
			else
			{
				if (documentType == typeof(PSObject))
					PSObjectSerializer.Register();

				WriteObject(cursor, true);
			}
		}
	}
}
