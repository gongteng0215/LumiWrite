#define MyAppName "LumiWrite"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "LumiWrite"
#define MyAppExeName "LumiWrite.exe"
#define MyAppId "{{D7E8A4D8-6E6C-4B52-9E58-7B2E1B0B1C7D}}"
#define MyBuildDir "build\\windows\\x64\\runner\\Release"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename={#MyAppName}-Setup
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
ChangesAssociations=yes
SetupIconFile={#MyBuildDir}\{#MyAppExeName}

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; Flags: unchecked
Name: "assocmd"; Description: "Associate .md files with {#MyAppName}"
Name: "assocmarkdown"; Description: "Associate .markdown files with {#MyAppName}"

[Files]
Source: "{#MyBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Classes\.md"; ValueType: string; ValueData: "LumiWrite.Markdown"; Flags: uninsdeletevalue; Tasks: assocmd
Root: HKCU; Subkey: "Software\Classes\.markdown"; ValueType: string; ValueData: "LumiWrite.Markdown"; Flags: uninsdeletevalue; Tasks: assocmarkdown
Root: HKCU; Subkey: "Software\Classes\LumiWrite.Markdown"; ValueType: string; ValueData: "Markdown Document"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\LumiWrite.Markdown\DefaultIcon"; ValueType: string; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\LumiWrite.Markdown\shell\open\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
