$ErrorActionPreference = 'Stop'
$doc = [System.Xml.XmlDocument]::new()
$root = $doc.CreateElement('roblox')
$root.SetAttribute('version','4')
[void]$doc.AppendChild($root)
$script:nextId = 0
function Add-Item($parent, $class, $name, $source) {
    $item = $doc.CreateElement('Item')
    $item.SetAttribute('class',$class)
    $script:nextId++
    $item.SetAttribute('referent',"RBX$script:nextId")
    [void]$parent.AppendChild($item)
    $props = $doc.CreateElement('Properties')
    [void]$item.AppendChild($props)
    $n = $doc.CreateElement('string')
    $n.SetAttribute('name','Name')
    $n.InnerText = $name
    [void]$props.AppendChild($n)
    if ($source) {
        $s = $doc.CreateElement('ProtectedString')
        $s.SetAttribute('name','Source')
        $s.InnerText = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot $source))
        [void]$props.AppendChild($s)
    }
    return $item
}
$workspace = Add-Item $root 'Workspace' 'Workspace' $null
$starter = Add-Item $root 'StarterPlayer' 'StarterPlayer' $null
$scripts = Add-Item $starter 'StarterPlayerScripts' 'StarterPlayerScripts' $null
[void](Add-Item $scripts 'LocalScript' 'AgarMinhoca' 'src/Jogo.client.luau')
$server = Add-Item $root 'ServerScriptService' 'ServerScriptService' $null
[void](Add-Item $server 'Script' 'Sessao' 'src/Sessao.server.luau')
$outputPath = Join-Path $PSScriptRoot 'AgarMinhoca.rbxlx'
$doc.Save($outputPath)
Write-Output $outputPath
