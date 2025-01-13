$mapper = [LiteDB.BSONMapper]::new()

function DBOpen([string]$connectionString) {
    [LiteDB.LiteDatabase]::new($connectionString)
}

function Get-DBCollection($db, $name) {
    $db.GetCollection($name)
}

function ToDocument($obj) {
    ,$mapper.ToDocument($obj)
}

function ToObject($type, $obj) {
    ,$mapper.ToObject($type, $obj)
}

function DBInsert([LiteDB.LiteCollection[LiteDB.BSONDocument]]$collection, $item) {
    $collection.Insert((ToDocument $item)) | out-null
}

function DBUpdate([LiteDB.LiteCollection[LiteDB.BSONDocument]]$collection, $item) {
    $collection.Update((ToDocument $item))
}

function DBDelete([LiteDB.LiteCollection[LiteDB.BSONDocument]]$collection, $query) {
    $collection.DeleteMany($query)
}

function DBGetById([LiteDB.LiteCollection[LiteDB.BSONDocument]]$collection, $id, $type) {
    Find $collection ([LiteDB.Query]::EQ('_id', [LiteDB.BSONValue]::new($id))) $type
}

function Find([LiteDB.LiteCollection[LiteDB.BSONDocument]]$collection, $query, $type) {
    ForEach($document in $collection.Find($query)) {
        ToObject $type $document
    }
}

function DBCreateMatchQuery($matches) {
    $query = [LiteDB.Query]::All()
    ForEach($prop in (getEnum $matches)) {
        $query = [LiteDB.Query]::And([LiteDB.Query]::EQ($prop.Name, $prop.Value), $query)
    }
    ,$query
}
