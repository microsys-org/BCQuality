codeunit 50272 "Sample InStream Length Bad"
{
    var
        MaxSimpleUploadSize: Integer;

    procedure Upload(var Stream: InStream; FileName: Text)
    var
        SimpleResp: HttpResponseMessage;
        ChunkedResp: HttpResponseMessage;
    begin
        MaxSimpleUploadSize := 4 * 1024 * 1024;
        // Wrong: Stream.Length is 0 or unreliable for streams from HTTP
        // responses, some file APIs, and caller-supplied streams.
        if Stream.Length <= MaxSimpleUploadSize then
            UploadSimple(Stream, FileName, SimpleResp)
        else
            UploadChunked(Stream, FileName, ChunkedResp);
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
