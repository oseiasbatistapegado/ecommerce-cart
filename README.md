# Desafio técnico e-commerce

## Nossas expectativas

A equipe de engenharia da RD Station tem alguns princípios nos quais baseamos nosso trabalho diário. Um deles é: projete seu código para ser mais fácil de entender, não mais fácil de escrever.

Portanto, para nós, é mais importante um código de fácil leitura do que um que utilize recursos complexos e/ou desnecessários.

O que gostaríamos de ver:

- O código deve ser fácil de ler. Clean Code pode te ajudar.
- Notas gerais e informações sobre a versão da linguagem e outras informações importantes para executar seu código.
- Código que se preocupa com a performance (complexidade de algoritmo).
- O seu código deve cobrir todos os casos de uso presentes no README, mesmo que não haja um teste implementado para tal.
- A adição de novos testes é sempre bem-vinda.
- Você deve enviar para nós o link do repositório público com a aplicação desenvolvida (GitHub, BitBucket, etc.).

## O Desafio - Carrinho de compras
O desafio consiste em uma API para gerenciamento do um carrinho de compras de e-commerce.

Você deve desenvolver utilizando a linguagem Ruby e framework Rails, uma API Rest que terá 3 endpoins que deverão implementar as seguintes funcionalidades:

### 1. Registrar um produto no carrinho
Criar um endpoint para inserção de produtos no carrinho.

Se não existir um carrinho para a sessão, criar o carrinho e salvar o ID do carrinho na sessão.

Adicionar o produto no carrinho e devolver o payload com a lista de produtos do carrinho atual.


ROTA: `/cart`
Payload:
```js
{
  "product_id": 345, // id do produto sendo adicionado
  "quantity": 2, // quantidade de produto a ser adicionado
}
```

Response
```js
{
  "id": 789, // id do carrinho
  "products": [
    {
      "id": 645,
      "name": "Nome do produto",
      "quantity": 2,
      "unit_price": 1.99, // valor unitário do produto
      "total_price": 3.98, // valor total do produto
    },
    {
      "id": 646,
      "name": "Nome do produto 2",
      "quantity": 2,
      "unit_price": 1.99,
      "total_price": 3.98,
    },
  ],
  "total_price": 7.96 // valor total no carrinho
}
```

### 2. Listar itens do carrinho atual
Criar um endpoint para listar os produtos no carrinho atual.

ROTA: `/cart`

Response:
```js
{
  "id": 789, // id do carrinho
  "products": [
    {
      "id": 645,
      "name": "Nome do produto",
      "quantity": 2,
      "unit_price": 1.99, // valor unitário do produto
      "total_price": 3.98, // valor total do produto
    },
    {
      "id": 646,
      "name": "Nome do produto 2",
      "quantity": 2,
      "unit_price": 1.99,
      "total_price": 3.98,
    },
  ],
  "total_price": 7.96 // valor total no carrinho
}
```

### 3. Alterar a quantidade de produtos no carrinho 
Um carrinho pode ter _N_ produtos, se o produto já existir no carrinho, apenas a quantidade dele deve ser alterada

ROTA: `/cart/add_item`

Payload
```json
{
  "product_id": 1230,
  "quantity": 1
}
```
Response:
```json
{
  "id": 1,
  "products": [
    {
      "id": 1230,
      "name": "Nome do produto X",
      "quantity": 2, // considerando que esse produto já estava no carrinho
      "unit_price": 7.00, 
      "total_price": 14.00, 
    },
    {
      "id": 01020,
      "name": "Nome do produto Y",
      "quantity": 1,
      "unit_price": 9.90, 
      "total_price": 9.90, 
    },
  ],
  "total_price": 23.9
}
```

### 3. Remover um produto do carrinho 

Criar um endpoint para excluir um produto do do carrinho. 

ROTA: `/cart/:product_id`


#### Detalhes adicionais:

- Verifique se o produto existe no carrinho antes de tentar removê-lo.
- Se o produto não estiver no carrinho, retorne uma mensagem de erro apropriada.
- Após remover o produto, retorne o payload com a lista atualizada de produtos no carrinho.
- Certifique-se de que o endpoint lida corretamente com casos em que o carrinho está vazio após a remoção do produto.

### 5. Excluir carrinhos abandonados
Um carrinho é considerado abandonado quando estiver sem interação (adição ou remoção de produtos) há mais de 3 horas.

- Quando este cenário ocorrer, o carrinho deve ser marcado como abandonado.
- Se o carrinho estiver abandonado há mais de 7 dias, remover o carrinho.
- Utilize um Job para gerenciar (marcar como abandonado e remover) carrinhos sem interação.
- Configure a aplicação para executar este Job nos períodos especificados acima.

### Detalhes adicionais:
- O Job deve ser executado regularmente para verificar e marcar carrinhos como abandonados após 3 horas de inatividade.
- O Job também deve verificar periodicamente e excluir carrinhos que foram marcados como abandonados por mais de 7 dias.

### Como resolver

#### Implementação
Você deve usar como base o código disponível nesse repositório e expandi-lo para que atenda as funcionalidade descritas acima.

Há trechos parcialmente implementados e também sugestões de locais para algumas das funcionalidades sinalizados com um `# TODO`. Você pode segui-los ou fazer da maneira que julgar ser a melhor a ser feita, desde que atenda os contratos de API e funcionalidades descritas.

#### Testes
Existem testes pendentes, eles estão marcados como <span style="color:green;">Pending</span>, e devem ser implementados para garantir a cobertura dos trechos de código implementados por você.
Alguns testes já estão passando e outros estão com erro. Com a sua implementação os testes com erro devem passar a funcionar. 
A adição de novos testes é sempre bem-vinda, mas sem alterar os já implementados.


### O que esperamos
- Implementação dos testes faltantes e de novos testes para os métodos/serviços/entidades criados
- Construção das 4 rotas solicitadas
- Implementação de um job para controle dos carrinhos abandonados


### Itens adicionais / Legais de ter
- Utilização de factory na construção dos testes
- Desenvolvimento do docker-compose / dockerização da app

A aplicação já possui um Dockerfile, que define como a aplicação deve ser configurada dentro de um contêiner Docker. No entanto, para completar a dockerização da aplicação, é necessário criar um arquivo `docker-compose.yml`. O arquivo irá definir como os vários serviços da aplicação (por exemplo, aplicação web, banco de dados, etc.) interagem e se comunicam.

- Adicione tratamento de erros para situações excepcionais válidas, por exemplo: garantir que um produto não possa ter quantidade negativa. 

- Se desejar você pode adicionar a configuração faltante no arquivo `docker-compose.yml` e garantir que a aplicação rode de forma correta utilizando Docker. 

## Informações técnicas

### Dependências
- ruby 3.3.1
- rails 7.1.3.2
- postgres 16
- redis 7.0.15

### Como executar o projeto

## Executando a app sem o docker
Dado que todas as as ferramentas estão instaladas e configuradas:

Instalar as dependências do:
```bash
bundle install
```

Executar o sidekiq:
```bash
bundle exec sidekiq
```

Executar projeto:
```bash
bundle exec rails server
```

Executar os testes:
```bash
bundle exec rspec
```

## Decisões de Arquitetura

### Por que usar Redis para gerenciar o carrinho?

A decisão de utilizar Redis para armazenar os carrinhos de compras foi baseada em várias considerações técnicas e de performance:

1. **Performance e Escalabilidade**: Redis é uma solução em memória extremamente rápida, ideal para operações de leitura e escrita frequentes. Em um e-commerce, o carrinho é uma das funcionalidades mais acessadas, e o Redis oferece latência sub-milissegundo para essas operações.

2. **Estruturas de Dados Adequadas**: Redis oferece estruturas de dados nativas que se encaixam perfeitamente com o modelo de carrinho:
   - **Hashes**: Para armazenar os dados do carrinho (produtos, status, timestamps) de forma estruturada
   - **Sorted Sets**: Para rastrear a última atividade dos carrinhos de forma eficiente, permitindo consultas por intervalo de tempo (ex: carrinhos sem atividade há mais de 3 horas)

3. **Sessões Stateless**: Como os carrinhos são gerenciados por sessão, o Redis permite que a aplicação seja facilmente escalável horizontalmente, sem depender de sessões locais do servidor.

4. **Operações Atômicas**: Redis oferece transações e operações atômicas (MULTI/EXEC, WATCH) que garantem consistência nas operações de adicionar/remover produtos, evitando condições de corrida.

5. **TTL Nativo**: Redis possui suporte nativo para TTL (Time To Live), permitindo que os dados expirem automaticamente sem necessidade de jobs adicionais de limpeza.

### Por que usar TTL de 7 dias ao invés de um job de remoção?

A escolha de utilizar o TTL (Time To Live) nativo do Redis para remover carrinhos abandonados após 7 dias, ao invés de implementar um job separado, foi uma decisão baseada nos seguintes fatores:

1. **Simplicidade e Manutenibilidade**: O TTL do Redis é uma funcionalidade nativa e confiável. Ao utilizá-lo, eliminamos a necessidade de:
   - Um job adicional de remoção
   - Lógica complexa para identificar carrinhos a serem removidos
   - Tratamento de erros e edge cases relacionados à remoção manual
   - Monitoramento de um job adicional

2. **Performance**: A remoção via TTL é automática e acontece no nível do Redis, sem overhead de processamento na aplicação. Não há necessidade de:
   - Escanear todos os carrinhos no Redis (operação custosa com `KEYS`)
   - Processar em lotes
   - Gerenciar locks ou condições de corrida

3. **Confiabilidade**: O TTL é gerenciado internamente pelo Redis de forma eficiente e confiável. Não há risco de:
   - Jobs falhando e deixando carrinhos órfãos
   - Problemas de sincronização entre marcação e remoção
   - Dependências entre jobs

4. **Recursos do Sistema**: Ao eliminar o job de remoção, reduzimos:
   - Uso de CPU e memória do Sidekiq
   - Tráfego de rede entre aplicação e Redis
   - Complexidade do sistema

5. **Aderência ao Princípio KISS**: A solução segue o princípio "Keep It Simple, Stupid" - utilizamos uma funcionalidade nativa e testada do Redis ao invés de reinventar a roda com lógica customizada.

**Estratégia Implementada:**
- O job `MarkCartAsAbandonedJob` roda a cada 2 minutos e marca carrinhos sem atividade há mais de 3 horas como abandonados
- Cada carrinho no Redis possui um TTL de 7 dias configurado automaticamente
- Após 7 dias, o Redis remove o carrinho automaticamente, sem necessidade de intervenção da aplicação
- Isso garante que carrinhos abandonados há mais de 7 dias sejam removidos de forma eficiente e automática

### Como enviar seu projeto
Salve seu código em um versionador de código (GitHub, GitLab, Bitbucket) e nos envie o link publico. Se achar necessário, informe no README as instruções para execução ou qualquer outra informação relevante para correção/entendimento da sua solução.
