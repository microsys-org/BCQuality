codeunit 50271 "Sample Case With Else Good"
{
    var
        UnsupportedAuthTypeErr: Label 'Authentication type %1 is not supported.', Comment = '%1 = Authentication Type value';

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
            else
                Error(UnsupportedAuthTypeErr, SharePointAccount."Authentication Type");
        end;
    end;
}
