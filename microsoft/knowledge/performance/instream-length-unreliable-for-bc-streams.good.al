codeunit 50273 "Sample InStream Length Good"
{
    var
        MaxSimpleUploadSize: Integer;

    procedure Upload(var Stream: InStream; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        SizedStream: InStream;
        BufferLength: Integer;
        SimpleResp: HttpResponseMessage;
        ChunkedResp: HttpResponseMessage;
    begin
        MaxSimpleUploadSize := 4 * 1024 * 1024;
        // Materialise once into a Temp Blob; its length is reliable.
        CopyStream(TempBlob.CreateOutStream(), Stream);
        BufferLength := TempBlob.Length();
        TempBlob.CreateInStream(SizedStream);

        if (BufferLength > 0) and (BufferLength <= MaxSimpleUploadSize) then
            UploadSimple(SizedStream, FileName, SimpleResp)
        else
            UploadChunked(SizedStream, FileName, ChunkedResp);
    end;

    local procedure UploadSimple(var Stream: InStream; FileName: Text; var Response: HttpResponseMessage)
    begin
        // ... PUT to /items/{id}/content endpoint
    end;

    local procedure UploadChunked(var Stream: InStream; FileName: Text; var Response: HttpResponseMessage)
    begin
        // ... POST to /items/{id}/createUploadSession endpoint, then PUT in chunks
    end;
}
