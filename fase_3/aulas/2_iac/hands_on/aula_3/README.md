# Aula 3 – Projeto Prático (Módulos, Loops e Condicionais)

Este projeto demonstra o uso de:
- Módulos locais e públicos
- Loops (`count` e `for_each`)
- Condicionais (`ternary` e recurso opcional)
- Dynamic blocks
- For expressions
- Ambientes dev/prod com `.tfvars`

## Estrutura
- `main.tf` → Projeto principal com exemplos de todos os conceitos
- `modules/network/` → Módulo local para criação de VPC e subnets
- `dev.tfvars` → Configuração para ambiente de desenvolvimento
- `prod.tfvars` → Configuração para ambiente de produção

## Como usar

1. Inicialize o projeto:
```bash
terraform init
```

2. Planeje para o ambiente de desenvolvimento:
```bash
terraform plan -var-file="dev.tfvars"
```

3. Aplique em desenvolvimento:
```bash
terraform apply -var-file="dev.tfvars"
```

4. Visualize os outputs:
```bash
terraform output
```

5. Destrua o ambiente dev:
```bash
terraform destroy -var-file="dev.tfvars"
```

6. Repita os passos para `prod.tfvars` se desejar simular produção.


1. for_each
O que faz: Cria múltiplos recursos a partir de um mapa ou conjunto (set).
Quando usar: Ideal para cenários onde cada instância de recurso precisa ser diferente, mas baseada em um conjunto de dados pré-definido.
Como funciona: Itera sobre cada item do mapa ou conjunto, usando a chave ou o valor para nomear ou identificar unicamente cada recurso criado.
Exemplo: Criar múltiplos grupos de recursos em um provedor de nuvem, onde cada grupo recebe um nome diferente de uma lista definida. 

2. count
O que faz: Cria múltiplas instâncias de um recurso idêntico com base em um número. 
Quando usar: Útil quando você sabe exatamente quantas instâncias de um recurso idêntico precisa e a única coisa que muda é um índice numérico, como na criação de várias máquinas virtuais com configurações básicas idênticas. 
Como funciona: Itera um número especificado de vezes, referenciando cada instância através do seu índice (count.index). 
Limitações: Não pode ser usado em tipos de dados indexados como listas para criar recursos individuais, sendo recomendado o for_each neste caso. 

3. Expressão for
O que faz: Constrói listas ou mapas a partir de coleções de dados (listas ou mapas) existentes.
Quando usar: Para transformar, filtrar ou processar dados antes de utilizá-los em outros recursos, saídas ou variáveis.
Como funciona: Pode ser usada para criar uma nova coleção de dados a partir de uma existente, usando a sintaxe { for item in list : key => value }.
Exemplo: Filtrar uma lista de instâncias para criar um novo mapa com apenas as instâncias que atendem a uma determinada condição. 

Benefícios
Eficiência: Reduz a repetição de código ao criar vários recursos de forma automatizada. 
Flexibilidade: Permite ajustes fáceis no número de recursos conforme os requisitos mudam. 
Consistência: Garante que todos os recursos criados pela mesma lógica tenham configurações uniformes. 