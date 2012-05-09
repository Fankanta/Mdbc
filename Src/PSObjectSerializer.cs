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
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using MongoDB.Bson;
using MongoDB.Bson.IO;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
namespace Mdbc
{
	public class PSObjectSerializer : BsonBaseSerializer
	{
		static bool _registered;
		internal static void Register()
		{
			if (!_registered)
			{
				_registered = true;
				BsonSerializer.RegisterSerializer(typeof(PSObject), new PSObjectSerializer());
			}
		}
		static IList ReadArray(BsonReader bsonReader)
		{
			var array = new ArrayList();

			bsonReader.ReadStartArray();
			while (bsonReader.ReadBsonType() != BsonType.EndOfDocument)
				array.Add(ReadObject(bsonReader));
			bsonReader.ReadEndArray();

			return array;
		}
		static object ReadObject(BsonReader bsonReader) //_120509_173140 keep consistent
		{
			switch (bsonReader.GetCurrentBsonType())
			{
				case BsonType.Array: return ReadArray(bsonReader); // replacement
				case BsonType.Binary: var binary = BsonBinaryData.ReadFrom(bsonReader); return binary.RawValue ?? binary; // byte[] or Guid else self
				case BsonType.Boolean: return bsonReader.ReadBoolean();
				case BsonType.DateTime: return BsonUtils.ToDateTimeFromMillisecondsSinceEpoch(bsonReader.ReadDateTime());
				case BsonType.Document: return ReadCustomObject(bsonReader); // replacement
				case BsonType.Double: return bsonReader.ReadDouble();
				case BsonType.Int32: return bsonReader.ReadInt32();
				case BsonType.Int64: return bsonReader.ReadInt64();
				case BsonType.Null: bsonReader.ReadNull(); return null;
				case BsonType.String: return bsonReader.ReadString();
				default: return BsonValue.ReadFrom(bsonReader);
			}
		}
		static PSObject ReadCustomObject(BsonReader bsonReader)
		{
			var ps = new PSObject();
			var properties = ps.Properties;

			bsonReader.ReadStartDocument();
			while (bsonReader.ReadBsonType() != BsonType.EndOfDocument)
			{
				var name = bsonReader.ReadName();
				var value = ReadObject(bsonReader);
				properties.Add(new PSNoteProperty(name, value), true); //! true is faster
			}
			bsonReader.ReadEndDocument();

			return ps;
		}
		public override object Deserialize(BsonReader bsonReader, Type nominalType, Type actualType, IBsonSerializationOptions options)
		{
			if (bsonReader.GetCurrentBsonType() == BsonType.Null)
			{
				bsonReader.ReadNull();
				return null;
			}

			return ReadCustomObject(bsonReader);
		}
	}
}
