#!/bin/bash

# Script para monitorar containers Docker
# Mostra containers, status, rede, IP e verifica conectividade
# Versão 1.1 @cybersecwonderwoman
#
# Copyright (C) 2025 Anny Ribeiro
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para mostrar o cabeçalho
print_header() {
    echo -e "${BLUE}===========================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================================================${NC}"
}

# Função para verificar se o Docker está instalado e em execução
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker não está instalado. Por favor, instale o Docker primeiro.${NC}"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${RED}O serviço Docker não está em execução. Por favor, inicie o serviço Docker.${NC}"
        exit 1
    fi
}

# Função para listar todos os containers (ativos e inativos)
list_containers() {
    print_header "LISTA DE TODOS OS CONTAINERS (ATIVOS E INATIVOS)"
    docker ps -a
    echo ""
}

# Função para mostrar containers ativos
active_containers() {
    print_header "CONTAINERS ATIVOS"
    docker ps
    echo ""
}

# Função para mostrar informações detalhadas de redes
show_networks() {
    print_header "REDES DOCKER DISPONÍVEIS"
    docker network ls
    echo ""
    
    # Listar containers disponíveis
    print_header "CONTAINERS DISPONÍVEIS"
    docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Status}}"
    echo ""
    
    # Perguntar qual container o usuário deseja verificar
    echo -e "${YELLOW}Digite o nome ou ID do container para ver suas informações de rede${NC}"
    echo -e "${YELLOW}(ou deixe em branco para ver todas as redes):${NC} "
    read container_name
    
    if [ -z "$container_name" ]; then
        # Se nenhum container for especificado, mostrar todas as redes
        print_header "DETALHES DE TODAS AS REDES"
        networks=$(docker network ls --format "{{.Name}}")
        
        for network in $networks; do
            echo -e "${YELLOW}Rede: $network${NC}"
            docker network inspect $network | grep -E "Name|IPv|Gateway|Container" -A 3
            echo -e "${BLUE}-------------------------------------------------------------------${NC}"
        done
    else
        # Verificar se o container existe
        if ! docker ps -a --format "{{.Names}}" | grep -q "^$container_name$"; then
            echo -e "${RED}Container '$container_name' não encontrado!${NC}"
            return
        fi
        
        # Mostrar informações de rede do container específico
        print_header "INFORMAÇÕES DE REDE PARA O CONTAINER: $container_name"
        
        # Obter as redes às quais o container está conectado
        container_networks=$(docker inspect $container_name --format '{{range $net,$v := .NetworkSettings.Networks}}{{$net}} {{end}}')
        
        if [ -z "$container_networks" ]; then
            echo -e "${RED}O container '$container_name' não está conectado a nenhuma rede.${NC}"
            return
        fi
        
        echo -e "${YELLOW}O container está conectado às seguintes redes:${NC} $container_networks"
        echo ""
        
        for network in $container_networks; do
            echo -e "${BLUE}Detalhes da rede: $network${NC}"
            echo -e "${YELLOW}Informações do container na rede:${NC}"
            docker inspect $container_name --format "{{range \$k, \$v := .NetworkSettings.Networks}}{{if eq \$k \"$network\"}}IP: {{\$v.IPAddress}}, Gateway: {{\$v.Gateway}}, MacAddress: {{\$v.MacAddress}}{{end}}{{end}}"
            echo ""
            
            echo -e "${YELLOW}Outros containers na mesma rede:${NC}"
            other_containers=$(docker network inspect $network --format '{{range .Containers}}{{.Name}} ({{.IPv4Address}}) {{end}}' | sed "s/$container_name ([0-9.\/]*) //g")
            
            if [ -z "$other_containers" ]; then
                echo -e "${RED}Nenhum outro container nesta rede.${NC}"
            else
                echo "$other_containers"
            fi
            echo -e "${BLUE}-------------------------------------------------------------------${NC}"
        done
    fi
    echo ""
}

# Função para mostrar IPs dos containers
show_container_ips() {
    print_header "IPs DOS CONTAINERS"
    containers=$(docker ps --format "{{.Names}}")
    
    if [ -z "$containers" ]; then
        echo -e "${YELLOW}Nenhum container ativo encontrado.${NC}"
        return
    fi
    
    printf "%-30s %-20s %-20s %-20s\n" "NOME" "ID" "REDE" "ENDEREÇO IP"
    echo "------------------------------------------------------------------------------------------------"
    
    for container in $containers; do
        container_id=$(docker ps -f "name=$container" --format "{{.ID}}")
        networks=$(docker inspect $container --format '{{range $net,$v := .NetworkSettings.Networks}}{{$net}} {{end}}')
        
        for network in $networks; do
            ip=$(docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $container)
            printf "%-30s %-20s %-20s %-20s\n" "$container" "$container_id" "$network" "$ip"
        done
    done
    echo ""
}

# Função para testar conectividade entre containers
test_connectivity() {
    print_header "TESTE DE CONECTIVIDADE ENTRE CONTAINERS"
    containers=$(docker ps --format "{{.Names}}")
    container_count=$(echo "$containers" | wc -l)
    
    if [ -z "$containers" ] || [ "$container_count" -lt 2 ]; then
        echo -e "${YELLOW}Menos de 2 containers ativos encontrados. Não é possível testar conectividade.${NC}"
        return
    fi
    
    echo -e "${YELLOW}Testando conectividade entre containers...${NC}"
    echo ""
    
    for source in $containers; do
        for target in $containers; do
            if [ "$source" != "$target" ]; then
                target_ip=$(docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $target)
                
                if [ -n "$target_ip" ]; then
                    echo -e "${BLUE}Testando conexão de $source para $target ($target_ip)${NC}"
                    
                    # Tenta fazer ping do container de origem para o de destino
                    if docker exec $source ping -c 2 $target_ip &> /dev/null; then
                        echo -e "${GREEN}✓ Conectividade OK: $source pode acessar $target${NC}"
                    else
                        echo -e "${RED}✗ Falha de conectividade: $source não consegue acessar $target${NC}"
                    fi
                    
                    # Tenta verificar se o container de destino está escutando em alguma porta
                    ports=$(docker exec $target netstat -tuln 2>/dev/null || echo "")
                    if [ -n "$ports" ]; then
                        echo -e "${YELLOW}Portas abertas em $target:${NC}"
                        docker exec $target netstat -tuln | grep LISTEN
                    fi
                    echo ""
                fi
            fi
        done
    done
}

# Função para mostrar estatísticas de uso de recursos
show_stats() {
    print_header "ESTATÍSTICAS DE USO DE RECURSOS"
    docker stats --no-stream
    echo ""
}

# Menu principal
main_menu() {
    clear
    echo -e "${BLUE}===========================================================================${NC}"
    echo -e "${BLUE}                      MONITOR DE CONTAINERS DOCKER                         ${NC}"
    echo -e "${BLUE}                 Versão 1.1 @cybersecwonderwoman                          ${NC}"
    echo -e "${BLUE}===========================================================================${NC}"
    
    echo -e "${YELLOW}1.${NC} Listar todos os containers (ativos e inativos)"
    echo -e "${YELLOW}2.${NC} Mostrar apenas containers ativos"
    echo -e "${YELLOW}3.${NC} Mostrar informações de redes Docker"
    echo -e "${YELLOW}4.${NC} Mostrar IPs dos containers"
    echo -e "${YELLOW}5.${NC} Testar conectividade entre containers"
    echo -e "${YELLOW}6.${NC} Mostrar estatísticas de uso de recursos"
    echo -e "${YELLOW}7.${NC} Executar todas as verificações"
    echo -e "${YELLOW}0.${NC} Sair"
    echo -e "${BLUE}===========================================================================${NC}"
    echo -n "Digite sua escolha: "
    read choice
    
    case $choice in
        1) list_containers; press_enter ;;
        2) active_containers; press_enter ;;
        3) show_networks; press_enter ;;
        4) show_container_ips; press_enter ;;
        5) test_connectivity; press_enter ;;
        6) show_stats; press_enter ;;
        7) 
            list_containers
            active_containers
            show_networks
            show_container_ips
            test_connectivity
            show_stats
            press_enter
            ;;
        0) 
            clear
            echo -e "${YELLOW}Até a próxima!${NC}"
            exit 0 
            ;;
        *) echo -e "${RED}Opção inválida!${NC}"; sleep 2; main_menu ;;
    esac
}

# Função para "Pressione Enter para continuar"
press_enter() {
    echo ""
    echo -e "${BLUE}Pressione Enter para continuar...${NC}"
    read
    main_menu
}

# Verificar se o Docker está instalado e em execução
check_docker

# Iniciar o menu principal
main_menu
