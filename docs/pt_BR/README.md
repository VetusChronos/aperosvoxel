# Aperos Voxel

Aperos Voxel é um jogo voxel inspirado no Minecraft 
feito na Godot Engine v4.3.beta2 utilizando o modulo [godot_voxel](https://github.com/Zylann/godot_voxel).

Ainda está em fase alpha, e possui diversos problemas.

Este projeto foi baseado no [voxelgame](https://github.com/Zylann/voxelgame),
e já possui:

- Criação do mundo baseada na seed
- Splashes aleatórios no menu inicial
- Tipos de blocos
- Tipos de biomas (teste)
- Informações de [debug in-game](https://github.com/godot-extended-libraries/godot-debug-menu) apertando F3. Aperte F3 duas vezes para informações completas
- Inventário com ícones (não gerados automaticamente)
- Colocar e quebrar blocos do terreno
- Limite do mundo de 536.870.911 em todas as direções
- Salvamento do mundo em stream (limitado)

## TO-DO:

### Terrain
[ ] Geração de biomas mais completo, levando em consideração a temperatura, erosão e altura

### Save
[ ] Salvamento dos mundos baseados em um nome, id e versão

### Gameplay
[ ] Sistema de crafting dos itens<br>
[ ] Sistema de vida, fome e hidratação<br>
[ ] Limitar o avanço da água no terreno<br>

### Iluminação
[ ] Iluminação ambiente e oclusão ambiente voxel, semelhante ao do Minecraft

## Contribuição

Você é livre para contribuir para o projeto, seja reportando bugs e problemas desconhecidos.
Ou enviando pull requests de correções, implementações, texturas, sons etc. 
Deve-se ter em mente que o projeto é feito usando o modulo `godot_voxel`, então alguns dos problemas 
podem ser limitados ao modulo. Futuramente pode ser feito um fork do modulo
para um gerenciamento mais especifico do Aperos Voxel.

Por favor, ao enviar um pull request, atente-se ao padrão de nomenclatura dos métodos e variáveis, 
espaçamento entre os métodos etc.

Obs.: O projeto está utilizando opengl3 pois o meu humilde laptop não
roda bem no vulkan :<

**Textura**: [Excalibur](https://www.curseforge.com/minecraft/texture-packs/excalibur)