$ErrorActionPreference = 'Stop'
$destination = Join-Path $PSScriptRoot 'Luar de Cinzas.rbxlx'
$settings = [System.Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.Encoding = [System.Text.UTF8Encoding]::new($false)

function Start-RobloxItem($ClassName, $Name, $SourceFile) {
    $writer.WriteStartElement('Item')
    $writer.WriteAttributeString('class', $ClassName)
    $writer.WriteAttributeString('referent', "RBX$script:nextId")
    $script:nextId += 1
    $writer.WriteStartElement('Properties')
    $writer.WriteStartElement('string')
    $writer.WriteAttributeString('name', 'Name')
    $writer.WriteString($Name)
    $writer.WriteEndElement()
    if ($SourceFile) {
        $source = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot "src/$SourceFile"))
        $writer.WriteStartElement('ProtectedString')
        $writer.WriteAttributeString('name', 'Source')
        $writer.WriteString($source)
        $writer.WriteEndElement()
    }
    $writer.WriteEndElement()
}

$script:nextId = 1
$content = [System.IO.MemoryStream]::new()
$writer = [System.Xml.XmlWriter]::Create($content, $settings)
try {
    $writer.WriteStartElement('roblox')
    $writer.WriteAttributeString('version', '4')
    $writer.WriteElementString('External', 'null')
    $writer.WriteElementString('External', 'nil')

    Start-RobloxItem 'Workspace' 'Workspace'
    Start-RobloxItem 'Camera' 'Camera'
    $writer.WriteEndElement()
    $writer.WriteEndElement()

    Start-RobloxItem 'StarterPlayer' 'StarterPlayer'
    Start-RobloxItem 'StarterPlayerScripts' 'StarterPlayerScripts'
    Start-RobloxItem 'LocalScript' 'Jogo' 'Jogo.client.luau'
    foreach ($module in 'Arte', 'Fase', 'Movimento') {
        Start-RobloxItem 'ModuleScript' $module "$module.luau"
        $writer.WriteEndElement()
    }
    $writer.WriteEndElement()
    $writer.WriteEndElement()
    $writer.WriteEndElement()

    Start-RobloxItem 'ServerScriptService' 'ServerScriptService'
    Start-RobloxItem 'Script' 'Sessao' 'Sessao.server.luau'
    $writer.WriteEndElement()
    $writer.WriteEndElement()
    $writer.WriteEndElement()
    $writer.Flush()
    [System.IO.File]::WriteAllBytes($destination, $content.ToArray())
}
finally {
    $writer.Dispose()
    $content.Dispose()
}
Write-Output $destination
