codeunit 50270 "Sample Case No Else Bad"
{
    procedure InitializeGraphClient(var SharePointAccount: Record "Ext. SharePoint Account"; var GraphAuthInterface: Interface "Graph Auth Interface")
    var
        GraphAuthClientCredentials: Codeunit "Graph Auth Client Credentials";
        GraphAuthCertificate: Codeunit "Graph Auth Certificate";
    begin
        case SharePointAccount."Authentication Type" of
            SharePointAccount."Authentication Type"::"Client Secret":
                GraphAuthInterface := GraphAuthClientCredentials;
            SharePointAccount."Authentication Type"::Certificate:
                GraphAuthInterface := GraphAuthCertificate;
        end;
    end;
}
