﻿
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using MongoDB.Driver;
using System;
using System.Management.Automation;

namespace Mdbc.Commands
{
    [Cmdlet(VerbsCommon.Get, "MdbcData", DefaultParameterSetName = nsAll)]
	public sealed class GetDataCommand : AbstractCollectionCommand
	{
		const string nsAll = "All";
		const string nsDistinct = "Distinct";
		const string nsCount = "Count";
		const string nsRemove = "Remove";
		const string nsUpdate = "Update";

		[Parameter(Position = 0)]
		public object Query { get { return null; } set { _Query = Actor.ObjectToQuery(value); } }
		IMongoQuery _Query;

		[Parameter(Mandatory = true, ParameterSetName = nsDistinct)]
		public string Distinct { get; set; }

		[Parameter(Mandatory = true, ParameterSetName = nsCount)]
		public SwitchParameter Count { get; set; }

		[Parameter(Mandatory = true, ParameterSetName = nsRemove)]
		public SwitchParameter Remove { get; set; }

		[Parameter(Mandatory = true, ParameterSetName = nsUpdate)]
		public object Update { get { return null; } set { _Update = Actor.ObjectToUpdate(value, null); } }
		IMongoUpdate _Update;

		[Parameter(ParameterSetName = nsUpdate)]
		public SwitchParameter New { get; set; }

		[Parameter(ParameterSetName = nsUpdate)]
		public SwitchParameter Add { get; set; }

		[Parameter(ParameterSetName = nsAll)]
		[Parameter(ParameterSetName = nsCount)]
		[Parameter(ParameterSetName = nsRemove)]
		[Parameter(ParameterSetName = nsUpdate)]
		public QueryFlags Modes { get; set; }

		[Parameter(ParameterSetName = nsAll)]
		[Parameter(ParameterSetName = nsCount)]
		public int First { get; set; }

		[Parameter(ParameterSetName = nsAll)]
		[Parameter(ParameterSetName = nsCount)]
		public int Last { get; set; }

		[Parameter(ParameterSetName = nsAll)]
		[Parameter(ParameterSetName = nsCount)]
		public int Skip { get; set; }

		[Parameter(ParameterSetName = nsAll)]
		[Parameter(ParameterSetName = nsUpdate)]
		public object[] Property { get { return null; } set { _Fields = Actor.ObjectsToFields(value); } }
		IMongoFields _Fields;

		[Parameter(ParameterSetName = nsAll)]
		[Parameter(ParameterSetName = nsRemove)]
		[Parameter(ParameterSetName = nsUpdate)]
		public object[] SortBy { get { return null; } set { _SortBy = Actor.ObjectsToSortBy(value); } }
		IMongoSortBy _SortBy;

		[Parameter(ParameterSetName = nsAll)]
		[Parameter(ParameterSetName = nsRemove)]
		[Parameter(ParameterSetName = nsUpdate)]
		public PSObject As { get { return null; } set { _ParameterAs_ = new ParameterAs(value); } }
		Type DocumentType { get { return _ParameterAs_ == null ? typeof(Dictionary) : _ParameterAs_.Type; } }
		ParameterAs _ParameterAs_;

		[Parameter(ParameterSetName = nsUpdate)]
		public string ResultVariable { get; set; }

		void DoDistinct()
		{
			foreach (var it in TargetCollection.Distinct(Distinct, _Query))
				WriteObject(Actor.ToObject(it));
		}
		void DoRemove()
		{
			var document = TargetCollection.FindAndRemoveAs(DocumentType, _Query, _SortBy);
			if (document != null)
				WriteObject(document);
		}
		void DoUpdate()
		{
			UpdateResult result;
			var document = TargetCollection.FindAndModifyAs(DocumentType, _Query, _SortBy, _Update, _Fields, New, Add, out result);
			if (document != null)
				WriteObject(document);
			if (ResultVariable != null)
				SessionState.PSVariable.Set(ResultVariable, result);
		}
		bool DoLast()
		{
			if (Last <= 0)
				return false;

			Skip = (int)(TargetCollection.Count(_Query) - Skip - Last);
			First = Last;
			if (Skip >= 0)
				return false;

			First += Skip;
			if (First <= 0)
			{
				if (Count)
					WriteObject(0);
				return true;
			}
			Skip = 0;
			return false;
		}
		protected override void BeginProcessing()
		{
			if (First > 0 && Last > 0)
				throw new PSArgumentException("Parameters First and Last cannot be specified together.");

			try
			{
				switch (ParameterSetName)
				{
					case nsCount:
						if (First > 0 || Skip > 0 || Last > 0)
							break;

						WriteObject(TargetCollection.Count(_Query));
						return;

					case nsDistinct:
						DoDistinct();
						return;

					case nsRemove:
						DoRemove();
						return;

					case nsUpdate:
						DoUpdate();
						return;
				}

				// Last -> First and Skip
				if (DoLast())
					return;

				// Count
				if (Count)
				{
					WriteObject(TargetCollection.Count(_Query, Skip, First));
					return;
				}

				//_131018_160000 Do not use WriteObject(.., true), that seems to take a lot more memory
				foreach (var document in TargetCollection.FindAs(DocumentType, _Query, Modes, _SortBy, Skip, First, _Fields))
					WriteObject(document);
			}
			catch (MongoException ex)
			{
				WriteException(ex, null);
			}
        }
    }
}
