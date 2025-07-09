# Docker Monitor 1.1

Um script de monitoramento para containers Docker que permite visualizar informações detalhadas sobre containers, redes, IPs e conectividade.

## ⚙️ Funcionalidades

O Docker Monitor oferece as seguintes funcionalidades:

1. **Listar todos os containers** (ativos e inativos)
2. **Mostrar apenas containers ativos**
3. **Mostrar informações de redes Docker**
   - Permite selecionar um container específico para ver suas informações de rede
   - Mostra outros containers na mesma rede
4. **Mostrar IPs dos containers**
   - Exibe nome, ID, rede e endereço IP de cada container
5. **Testar conectividade entre containers**
   - Verifica se os containers podem se comunicar entre si
   - Mostra portas abertas nos containers
6. **Mostrar estatísticas de uso de recursos**
   - CPU, memória e uso de rede
7. **Executar todas as verificações** acima de uma vez

## 📝 Requisitos

- Docker instalado e em execução
- Bash shell
- Permissões para executar comandos Docker

## ⏬ Instalação

1. Baixe o script para seu sistema:
```bash
curl -o docker_monitor.sh https://raw.githubusercontent.com/seu-usuario/docker-monitor/main/docker_monitor.sh
```

2. Torne o script executável:
```bash
chmod +x docker_monitor.sh
```

## Uso

Execute o script com:

```bash
./docker_monitor.sh
```

Você verá um menu interativo com as opções disponíveis. Selecione a opção desejada digitando o número correspondente.

### Exemplos de uso

- Para verificar todos os containers ativos e inativos, selecione a opção 1
- Para testar a conectividade entre containers, selecione a opção 5
- Para obter informações detalhadas sobre as redes de um container específico, selecione a opção 3

## ✏️ Personalização

O script usa cores para melhorar a legibilidade. Você pode personalizar as cores editando as variáveis no início do script:

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
```

## ⁉️ Solução de problemas

- Se o script retornar um erro sobre Docker não estar instalado, verifique se o Docker está instalado e em execução
- Se você não conseguir ver informações de rede para um container, verifique se o container está em execução
- Para problemas de conectividade, verifique se os containers estão na mesma rede Docker

## Contribuição

Feito  Por @cybersecwonderwoman com ❤️ para a comunidade Docker.

Se você achar esta ferramenta útil, considere dar um ⭐ no GitHub!
