# AgarMinhoca

Protótipo solo 2D para Roblox, inspirado na coleta e crescimento de Agar.io, com personagens em formato de minhoca. Projeto independente de Vamp.

## Testar

1. Abra `AgarMinhoca.rbxlx` no Roblox Studio.
2. Pressione F5 (Play) e clique em JOGAR.
3. Mova com o mouse ou WASD. Espaço acelera e consome massa. R reinicia.
4. Em dispositivos de toque, arraste na arena para direcionar e segure TURBO para acelerar.

São 420 bolinhas e 9 bots. Cada bolinha vale 1 de massa. Para capturar outro jogador, sua massa precisa ser pelo menos 1,2 vez a dele e as cabeças precisam se sobrepor. A captura rende 75% da massa do adversário. Corpos não causam colisões. Há proteção de 4 segundos ao nascer. Bots reaparecem; após perder, clique em JOGAR NOVAMENTE.

O ranking e o recorde são apenas da sessão. Esta versão simula tudo no cliente e não oferece multiplayer real, salvamento, loja ou publicação automática. Uma versão online exigirá simulação e validação no servidor.

## Recompilar

Execute `Gerar-Projeto.ps1` no PowerShell para gerar o arquivo Roblox a partir de `src`. Reabra o arquivo no Studio após recompilar.
